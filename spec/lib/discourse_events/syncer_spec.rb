# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::Syncer do
  subject { DiscourseEvents::Syncer }

  # rubocop:disable Discourse/Plugins/NoMonkeyPatching
  DiscourseEvents::Syncer.class_eval do
    def create_event_topic(event)
      create_event_post(event).topic
    end

    def update_event_topic(topic, event)
      topic.update_columns(title: event.name, fancy_title: nil, slug: nil)
      topic.first_post.update_columns(raw: post_raw(event))
      topic
    end

    def post_raw(event)
      event.description
    end
  end
  # rubocop:enable Discourse/Plugins/NoMonkeyPatching

  fab!(:source) { Fabricate(:discourse_events_source) }
  fab!(:category)
  fab!(:user)
  fab!(:admin) { Fabricate(:user, admin: true) }
  fab!(:connection) do
    Fabricate(:discourse_events_connection, source: source, category: category, user: user)
  end
  fab!(:event1) { Fabricate(:discourse_events_event, series_id: "ABC", occurrence_id: "1") }
  fab!(:event_source1) { Fabricate(:discourse_events_event_source, event: event1, source: source) }
  fab!(:event2) { Fabricate(:discourse_events_event, series_id: "ABC", occurrence_id: "2") }
  fab!(:event_source2) { Fabricate(:discourse_events_event_source, event: event2, source: source) }

  describe "sync" do
    def sync_events(opts = {})
      syncer = subject.new(user, connection)
      syncer.sync(opts)

      event1.reload
      event2.reload
    end

    it "syncs event data" do
      sync_events

      expect(event1.topics.first.title).to eq(event1.name)
    end

    it "updates event data" do
      new_name = "New event name"
      event1.name = new_name
      event1.save!

      sync_events

      expect(event1.topics.first.title).to eq(new_name)
    end

    it "returns ids of created and updated topics" do
      syncer = subject.new(user, connection)
      syncer.stubs(:create_events).returns([1])
      syncer.stubs(:update_events).returns([2, 3])
      result = syncer.sync

      expect(result).to eq({ created_topics: [1], updated_topics: [2, 3] })
    end

    it "does not trigger publication" do
      DiscourseEvents::PublishManager.expects(:perform).never
      sync_events
    end
  end

  context "with event series" do
    it "sources all events if source does not support event series" do
      connection.source.stubs(:supports_series).returns(false)

      syncer = subject.new(user, connection)
      expect(syncer.standard_events.size).to eq(2)
    end

    context "when source supports event series" do
      let(:first_start_time) { 2.days.from_now }
      let(:second_start_time) { 4.days.from_now }

      before do
        freeze_time

        event1.start_time = first_start_time
        event1.save
        event2.start_time = second_start_time
        event2.save

        connection.source.stubs(:supports_series).returns(true)
      end

      it "sources all events if events_ignore_series is enabled" do
        SiteSetting.events_ignore_series = true

        syncer = subject.new(user, connection)
        expect(syncer.standard_events.size).to eq(2)
      end

      it "sources series events" do
        syncer = subject.new(user, connection)
        expect(syncer.series_events.size).to eq(1)
        expect(syncer.series_events.first.start_time).to be_within(1.second).of(first_start_time)

        freeze_time(2.days.from_now + 1.hour)

        syncer = subject.new(user, connection)
        expect(syncer.series_events.size).to eq(1)
        expect(syncer.series_events.first.start_time).to be_within(1.second).of(second_start_time)
      end

      it "creates series event topics" do
        syncer = subject.new(user, connection)
        result = syncer.update_series_events_topics

        expect(result[:created_topics].size).to eq(1)
        expect(event1.event_connections.first.topic_id).to eq(result[:created_topics].first)
      end

      it "only creates one event connection per series topic" do
        syncer = subject.new(user, connection)
        syncer.update_series_events_topics
        syncer.update_series_events_topics

        expect(event1.event_connections.size).to eq(1)
      end
    end
  end

  context "with a connection filter" do
    fab!(:filter1) do
      Fabricate(:discourse_events_filter, model: connection, query_value: event2.name)
    end

    it "filters events" do
      syncer = subject.new(user, connection)
      expect(syncer.standard_events.size).to eq(1)
      expect(syncer.standard_events.first.name).to eq(event2.name)
    end
  end

  context "with a source filter" do
    fab!(:filter1) { Fabricate(:discourse_events_filter, model: source, query_value: event2.name) }

    it "filters events" do
      syncer = subject.new(user, connection)
      expect(syncer.standard_events.size).to eq(1)
      expect(syncer.standard_events.first.name).to eq(event2.name)
    end
  end
end
