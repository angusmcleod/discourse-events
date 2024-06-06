# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::SyncManager do
  subject { DiscourseEvents::SyncManager }

  fab!(:source) { Fabricate(:discourse_events_source) }
  fab!(:category)
  fab!(:user)
  fab!(:connection) do
    Fabricate(:discourse_events_connection, source: source, category: category, user: user)
  end
  fab!(:event) { Fabricate(:discourse_events_event, source: source) }

  it "syncs a connection" do
    subject.sync_connection(connection.id)

    topic = Topic.find_by(title: event.name, category_id: category.id)
    expect(topic.id).to eq(event.topics.first.id)
  end

  it "syncs all syncable connections" do
    subject.sync_all_connections

    topic = Topic.find_by(title: event.name, category_id: category.id)
    expect(topic.id).to eq(event.topics.first.id)
  end

  it "does not sync a connection if the client changes" do
    if SiteSetting.respond_to?(:calendar_enabled)
      SiteSetting.calendar_enabled = true
      SiteSetting.discourse_post_event_enabled = true
    end

    skip("Discourse Events is not installed") unless DiscourseEvents::DiscourseEventsSyncer.ready?

    result = subject.sync_connection(connection.id)
    expect(result).not_to eq(false)
    expect(result[:created_topics].size).to eq(1)

    connection.client = "discourse_events"
    connection.save!

    result = subject.sync_connection(connection.id)
    expect(result).not_to eq(false)
    expect(result[:updated_topics].size).to eq(0)
  end

  context "with event series" do
    fab!(:event1) do
      Fabricate(:discourse_events_event, source: source, series_id: "ABC", occurrence_id: "1")
    end
    fab!(:event2) do
      Fabricate(:discourse_events_event, source: source, series_id: "ABC", occurrence_id: "2")
    end

    before do
      DiscourseEvents::Source.any_instance.stubs(:supports_series).returns(true)
      SiteSetting.events_split_series_into_different_topics = false
    end

    it "syncs series events" do
      freeze_time

      first_start_time = 2.days.from_now
      second_start_time = 4.days.from_now

      event1.start_time = first_start_time
      event1.save
      event2.start_time = second_start_time
      event2.save

      result = subject.sync_connection(connection.id)
      expect(result).not_to eq(false)
      expect(result[:created_topics].size).to eq(2)
      expect(result[:updated_topics].size).to eq(0)
      expect(result[:created_topics]).to include(event1.reload.topics.first.id)

      freeze_time(2.days.from_now + 1.hour)

      result = subject.sync_connection(connection.id)
      expect(result[:created_topics].size).to eq(0)
      expect(result[:updated_topics].size).to eq(2)
      expect(result[:updated_topics]).to include(event2.reload.topics.first.id)
    end
  end
end
