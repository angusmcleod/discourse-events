# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::ImportManager do
  subject { DiscourseEvents::ImportManager }

  let(:uri) do
    File.join(File.expand_path("../../..", __dir__), "spec", "fixtures", "list_events.json")
  end
  let(:raw_data) { JSON.parse(File.open(uri).read).to_h }
  let!(:provider) { Fabricate(:discourse_events_provider) }
  let!(:source) { Fabricate(:discourse_events_source, source_options: { uri: uri }) }

  def raw_event_uids
    raw_data["events"].map { |event| event["id"] }
  end

  def event_uids
    DiscourseEvents::Event.all.map { |e| e.event_sources.map { |es| es.uid } }.flatten
  end

  context "with a subscription" do
    before { enable_subscription(:business) }

    it "imports a source" do
      subject.import_source(source.id)
      expect(event_uids).to match_array(raw_event_uids)
    end

    it "does not create a previously sourced event" do
      event = Fabricate(:discourse_events_event, start_time: "2017-09-18T16:00:00+08:00")
      event_source =
        Fabricate(
          :discourse_events_event_source,
          source: source,
          event: event,
          uid: raw_data["events"][0]["id"],
        )
      manager = subject.new(source)
      manager.setup
      manager.import
      expect(manager.created_event_uids.include?(raw_data["events"][0]["id"])).to eq(false)
    end

    it "imports all active sources" do
      subject.import_all_sources

      events = DiscourseEvents::Event.all
      expect(events.size).to eq(2)
      expect(events.first.event_sources.first.uid).to eq(raw_event_uids.first)
      expect(events.second.event_sources.first.uid).to eq(raw_event_uids.second)
    end

    it "logs imports" do
      subject.import_source(source.id)
      expect(DiscourseEvents::Log.all.first.message).to eq(
        I18n.t(
          "log.import_finished",
          source_name: source.name,
          events_count: 2,
          created_count: 2,
          updated_count: 0,
        ),
      )
    end

    context "with a filter" do
      let!(:filter) do
        Fabricate(
          :discourse_events_filter,
          model: source,
          query_column: DiscourseEvents::Filter.query_columns[:start_time],
          query_operator: DiscourseEvents::Filter.query_operators[:greater_than],
          query_value: "2022-8-18T12:30:00+02:00",
        )
      end

      it "applies the filter" do
        subject.import_all_sources

        events = DiscourseEvents::Event.all
        expect(events.size).to eq(1)
        expect(events.first.event_sources.first.uid).to eq(raw_event_uids.second)
      end
    end

    context "with a source import period" do
      before do
        freeze_time
        source.update(import_period: DiscourseEvents::Source::IMPORT_PERIODS["5_minutes"])
      end

      it "schedules the next import" do
        expect_enqueued_with(
          job: :discourse_events_import_source,
          args: {
            source_id: source.id,
          },
          at: 5.minutes.from_now,
        ) { subject.import_source(source.id) }
      end
    end

    context "with connections" do
      let!(:category1) { Fabricate(:category) }
      let!(:category2) { Fabricate(:category) }
      let!(:user) { Fabricate(:user) }
      let!(:connection1) do
        Fabricate(:discourse_events_connection, source: source, category: category1, user: user)
      end
      let!(:connection2) do
        Fabricate(
          :discourse_events_connection,
          source: source,
          category: category2,
          user: user,
          auto_sync: true,
        )
      end

      it "syncs auto_sync connections" do
        DiscourseEvents::SyncManager.expects(:sync_connection).with(connection1).never
        DiscourseEvents::SyncManager.expects(:sync_connection).with(connection2).once
        subject.import_source(source.id)
      end
    end
  end
end
