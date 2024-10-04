# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::DiscourseEventsSyncer do
  subject { DiscourseEvents::DiscourseEventsSyncer }

  fab!(:category)
  fab!(:user)
  fab!(:source) do
    Fabricate(:discourse_events_source, category: category, user: user, client: "discourse_events")
  end
  fab!(:event) { Fabricate(:discourse_events_event) }
  fab!(:event_source) { Fabricate(:discourse_events_event_source, event: event, source: source) }

  before do
    category.custom_fields["events_enabled"] = true
    category.save_custom_fields(true)

    SiteSetting.events_enabled = true
  end

  def sync_events(opts = {})
    syncer = subject.new(user: user, source: source, client: "discourse_events")
    syncer.sync(opts)

    event.reload
    Topic.find(event.event_topics.first.topic_id)
  end

  it "creates client event data" do
    topic = sync_events

    expect(topic.custom_fields["event_start"]).to eq(event.start_time.to_i)
    expect(topic.custom_fields["event_end"]).to eq(event.end_time.to_i)
  end

  it "updates client event data" do
    topic = sync_events

    new_name = "New event name"
    new_start_time = event.start_time + 5.days
    new_end_time = event.end_time + 5.days
    event.name = new_name
    event.start_time = new_start_time
    event.end_time = new_end_time
    event.save!

    sync_events

    topic = Topic.find(topic.id)
    expect(Topic.all.size).to eq(1)
    expect(topic.title).to eq(new_name)
    expect(topic.fancy_title).to eq(new_name)
    expect(topic.custom_fields["event_start"]).to eq(new_start_time.to_i)
    expect(topic.custom_fields["event_end"]).to eq(new_end_time.to_i)
  end

  context "with event registrations" do
    fab!(:event_registration1) do
      Fabricate(:discourse_events_event_registration, event: event, user: user, status: "confirmed")
    end

    it "creates event rsvps" do
      topic = sync_events
      expect(topic.event_going).to include(user.id)
    end
  end
end
