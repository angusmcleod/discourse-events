# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::EventsSyncer do
  subject { DiscourseEvents::EventsSyncer }

  let(:client) { "events" }

  fab!(:source) { Fabricate(:discourse_events_source) }
  fab!(:event) { Fabricate(:discourse_events_event, source: source) }
  fab!(:category) { Fabricate(:category) }
  fab!(:user) { Fabricate(:user) }
  fab!(:connection) { Fabricate(:discourse_events_connection, source: source, category: category, user: user) }

  before do
    skip("Client not installed") unless subject.ready?

    SiteSetting.events_enabled = true
  end

  def sync_events(opts = {})
    syncer = subject.new(user, connection)
    syncer.sync(opts)

    event.reload
    Topic.find(event.event_connections.first.topic_id)
  end

  it 'creates client event data' do
    topic = sync_events

    expect(topic.custom_fields['event_start']).to eq(event.start_time.to_i)
    expect(topic.custom_fields['event_end']).to eq(event.end_time.to_i)
  end

  it 'updates client event data' do
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
    expect(topic.custom_fields['event_start']).to eq(new_start_time.to_i)
    expect(topic.custom_fields['event_end']).to eq(new_end_time.to_i)
  end
end
