# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::Syncer::DiscourseCalendar do
  subject { DiscourseEvents::Syncer::DiscourseCalendar }

  fab!(:category)
  fab!(:user) { Fabricate(:user, admin: true) }
  fab!(:source) do
    Fabricate(
      :discourse_events_source,
      category: category,
      user: user,
      client: "discourse_calendar",
    )
  end
  fab!(:event) { Fabricate(:discourse_events_event) }
  fab!(:event_source) { Fabricate(:discourse_events_event_source, event: event, source: source) }

  before do
    unless DiscourseEvents.discourse_post_event_installed?
      skip("Discourse Calendar is not installed")
    end

    SiteSetting.calendar_enabled = true
    SiteSetting.discourse_post_event_enabled = true
  end

  def sync_events(opts = {})
    syncer = subject.new(user: user, source: source, client: "discourse_calendar")
    syncer.sync

    event.reload
    topic = Topic.find(event.event_topics.first.topic_id)
    post = topic.first_post

    CookedPostProcessor.new(post).post_process
    post.reload

    post
  end

  it "creates client event data" do
    post = sync_events
    expect(post.topic.id).to eq(event.topics.first.id)

    events = DiscoursePostEvent::Event.all
    expect(events.size).to eq(1)
    expect(events.first.original_starts_at).to be_within(1.second).of(event.start_time)
    expect(events.first.original_ends_at).to be_within(1.second).of(event.end_time)

    event_dates = DiscoursePostEvent::EventDate.all
    expect(event_dates.first.starts_at).to be_within(1.second).of(event.start_time)
    expect(event_dates.first.ends_at).to be_within(1.second).of(event.end_time)
  end

  it "updates client event data" do
    post = sync_events

    new_name = "New event name"
    new_start_time = event.start_time + 5.days
    new_end_time = event.end_time + 5.days
    event.name = new_name
    event.start_time = new_start_time
    event.end_time = new_end_time
    event.save!

    sync_events

    post.topic.reload
    expect(post.topic.title).to eq(new_name)
    expect(post.topic.fancy_title).to eq(new_name)

    events = DiscoursePostEvent::Event.all
    expect(events.size).to eq(1)
    expect(events.first.original_starts_at).to be_within(1.second).of(new_start_time)
    expect(events.first.original_ends_at).to be_within(1.second).of(new_end_time)

    event_dates = DiscoursePostEvent::EventDate.all
    expect(event_dates.first.starts_at).to be_within(1.second).of(new_start_time)
    expect(event_dates.first.ends_at).to be_within(1.second).of(new_end_time)
  end

  it "does not add end time if same as start time" do
    event.start_time = event.end_time
    event.save!

    post = sync_events

    expect(post.raw.include?("end=")).to eq(false)

    events = DiscoursePostEvent::Event.all
    expect(events.size).to eq(1)
    expect(events.first.original_ends_at).to be(nil)

    event_dates = DiscoursePostEvent::EventDate.all
    expect(event_dates.first.ends_at).to be(nil)
  end

  context "with event registrations" do
    fab!(:event_registration1) do
      Fabricate(:discourse_events_event_registration, event: event, user: user, status: "confirmed")
    end

    it "creates event invitees" do
      post = sync_events
      expect(post.event.invitees.first.user.id).to eq(user.id)
    end
  end

  context "with video url" do
    before do
      event.video_url = "https://zoom.com/12345"
      event.save!
    end

    it "serializes the video url in post event custom fields" do
      post = sync_events
      serialized_post =
        DiscoursePostEvent::EventSerializer.new(
          post.event,
          scope: Guardian.new(user),
          root: false,
        ).as_json
      expect(serialized_post[:custom_fields][:video_url]).to eq("https://zoom.com/12345")
    end
  end
end
