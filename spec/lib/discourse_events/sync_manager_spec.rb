# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::SyncManager do
  subject { DiscourseEvents::SyncManager }

  fab!(:category)
  fab!(:user)
  fab!(:source) { Fabricate(:discourse_events_source, category: category, user: user) }
  fab!(:event) { Fabricate(:discourse_events_event) }
  fab!(:event_source) { Fabricate(:discourse_events_event_source, event: event, source: source) }

  before do
    category.custom_fields["events_enabled"] = true
    category.save_custom_fields(true)

    SiteSetting.events_enabled = true
  end

  it "syncs a source" do
    subject.sync_source_by_id(source.id)

    topic = Topic.find_by(title: event.name, category_id: category.id)
    expect(topic.id).to eq(event.topics.first.id)
  end

  it "syncs all syncable sources" do
    subject.sync_all_sources

    topic = Topic.find_by(title: event.name, category_id: category.id)
    expect(topic.id).to eq(event.topics.first.id)
  end

  it "does not sync a source if the client changes" do
    unless DiscourseEvents::DiscourseCalendarSyncer.new(user, source).ready?
      skip("Discourse Calendar is not installed")
    end
    SiteSetting.calendar_enabled = true
    SiteSetting.discourse_post_event_enabled = true

    result = subject.sync_source_by_id(source.id)
    expect(result).not_to eq(false)
    expect(result[:created_topics].size).to eq(1)

    source.client = "discourse_calendar"
    source.save!

    result = subject.sync_source_by_id(source.id)
    expect(result).not_to eq(false)
    expect(result[:updated_topics].size).to eq(0)
  end

  context "with event series" do
    fab!(:event1) { Fabricate(:discourse_events_event, series_id: "ABC", occurrence_id: "1") }
    fab!(:event1_source) do
      Fabricate(:discourse_events_event_source, source: source, event: event1, uid: "12345")
    end
    fab!(:event2) { Fabricate(:discourse_events_event, series_id: "ABC", occurrence_id: "2") }
    fab!(:event2_source) do
      Fabricate(:discourse_events_event_source, source: source, event: event2, uid: "678910")
    end

    before do
      DiscourseEvents::Source.any_instance.stubs(:supports_series).returns(true)
      SiteSetting.events_one_event_per_series = true
    end

    it "syncs series events" do
      freeze_time

      first_start_time = 2.days.from_now
      second_start_time = 4.days.from_now

      event1.start_time = first_start_time
      event1.save
      event2.start_time = second_start_time
      event2.save

      result = subject.sync_source_by_id(source.id)
      expect(result).not_to eq(false)

      expect(result[:created_topics].size).to eq(2)
      expect(result[:updated_topics].size).to eq(0)
      expect(result[:created_topics]).to include(event1.reload.topics.first.id)

      freeze_time(2.days.from_now + 1.hour)

      result = subject.sync_source_by_id(source.id)
      expect(result[:created_topics].size).to eq(0)
      expect(result[:updated_topics].size).to eq(2)
      expect(result[:updated_topics]).to include(event2.reload.topics.first.id)
    end
  end

  context "when source has no user" do
    before do
      source.user = nil
      source.save!
    end

    it "does not sync" do
      result = subject.sync_source(source)
      expect(result).to eq(false)
      expect(DiscourseEvents::Log.all.first.message).to eq(
        I18n.t(
          "log.sync_client_not_ready",
          client_name: "Discourse events",
          provider_type: source.provider.provider_type,
          category_name: category.name,
        ),
      )
    end
  end
end
