# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::Syncer do
  subject { DiscourseEvents::Syncer }

  # rubocop:disable Discourse/Plugins/NoMonkeyPatching
  DiscourseEvents::Syncer.class_eval do
    def create_client_topic(event)
      create_post(event).topic
    end

    def update_client_topic(topic, event, add_raw: false)
      post = topic.first_post
      topic.update_columns(title: event.name, fancy_title: nil, slug: nil)
      topic.first_post.update_columns(raw: post_raw(event, post: post, add_raw: add_raw))
      topic
    end

    def update_client_registrations(topic, event)
    end

    def post_raw(event, post: nil, add_raw: false)
      raw = event.description
      raw += "\n\n#{post.raw}" if post && add_raw
      raw
    end
  end
  # rubocop:enable Discourse/Plugins/NoMonkeyPatching

  fab!(:source) { Fabricate(:discourse_events_source) }
  fab!(:category)
  fab!(:user)
  fab!(:admin) { Fabricate(:user, admin: true) }
  fab!(:event1) { Fabricate(:discourse_events_event, series_id: "ABC", occurrence_id: "1") }
  fab!(:event_source1) { Fabricate(:discourse_events_event_source, event: event1, source: source) }
  fab!(:event2) { Fabricate(:discourse_events_event, series_id: "ABC", occurrence_id: "2") }
  fab!(:event_source2) { Fabricate(:discourse_events_event_source, event: event2, source: source) }

  describe "sync" do
    def sync_events(opts = {})
      syncer = subject.new(user: user, source: source, client: source.client)
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
      syncer = subject.new(user: user, source: source, client: source.client)
      syncer.stubs(:create_events).returns([1])
      syncer.stubs(:update_events).returns([2, 3])
      result = syncer.sync

      expect(result).to eq({ created_topics: [1], updated_topics: [2, 3] })
    end

    it "does not trigger publication" do
      DiscourseEvents::PublishManager.expects(:publish).never
      sync_events
    end

    it "triggers client registrations update for each event" do
      DiscourseEvents::Syncer.any_instance.expects(:update_client_registrations).twice
      sync_events
    end
  end

  context "with event series" do
    it "sources all events if source does not support event series" do
      source.stubs(:supports_series).returns(false)

      syncer = subject.new(user: user, source: source, client: source.client)
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

        source.stubs(:supports_series).returns(true)
      end

      it "sources all events if events_one_event_per_series is disabled" do
        SiteSetting.events_one_event_per_series = false

        syncer = subject.new(user: user, source: source, client: source.client)
        expect(syncer.standard_events.size).to eq(2)
      end

      it "sources series events" do
        syncer = subject.new(user: user, source: source, client: source.client)
        expect(syncer.series_events.size).to eq(1)
        expect(syncer.series_events.first.start_time).to be_within(1.second).of(first_start_time)

        freeze_time(2.days.from_now + 1.hour)

        syncer = subject.new(user: user, source: source, client: source.client)
        expect(syncer.series_events.size).to eq(1)
        expect(syncer.series_events.first.start_time).to be_within(1.second).of(second_start_time)
      end

      it "creates series event topics" do
        syncer = subject.new(user: user, source: source, client: source.client)
        result = syncer.update_series_events_topics

        expect(result[:created_topics].size).to eq(1)
        expect(event1.event_topics.first.topic_id).to eq(result[:created_topics].first)
      end

      it "only creates one event topic per series topic" do
        syncer = subject.new(user: user, source: source, client: source.client)
        syncer.update_series_events_topics
        syncer.update_series_events_topics

        expect(event1.event_topics.size).to eq(1)
      end

      it "triggers client registrations update for each series event" do
        DiscourseEvents::Syncer.any_instance.expects(:update_client_registrations).once
        syncer = subject.new(user: user, source: source, client: source.client)
        syncer.update_series_events_topics
      end
    end
  end

  context "with a source filter" do
    fab!(:filter1) { Fabricate(:discourse_events_filter, model: source, query_value: event2.name) }

    it "filters events" do
      syncer = subject.new(user: user, source: source, client: source.client)
      expect(syncer.standard_events.size).to eq(1)
      expect(syncer.standard_events.first.name).to eq(event2.name)
    end
  end

  describe "#update_registrations" do
    fab!(:topic) { Fabricate(:topic, category: category) }
    fab!(:post) { Fabricate(:post, topic: topic) }
    fab!(:event_registration1) do
      Fabricate(
        :discourse_events_event_registration,
        event: event1,
        user: user,
        status: "confirmed",
      )
    end
    fab!(:event_registration2) { Fabricate(:discourse_events_event_registration, event: event1) }

    it "ensures registration users" do
      syncer = subject.new(user: user, source: source, client: source.client)
      expect { syncer.update_registrations(topic, event1) }.to change { User.count }.by(1)
      user2 = User.find_by_email(event_registration2.email)
      expect(user2.staged).to eq(true)
    end
  end
end
