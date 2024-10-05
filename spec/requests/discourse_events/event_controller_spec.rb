# frozen_string_literal: true

describe DiscourseEvents::EventController do
  fab!(:user) { Fabricate(:user, admin: true) }
  fab!(:event1) do
    Fabricate(:discourse_events_event, start_time: 1.hour.from_now, name: "Ben's party")
  end
  fab!(:topic1) { Fabricate(:topic) }
  fab!(:post1) { Fabricate(:post, topic: topic1, user: user, raw: event1.description) }
  fab!(:event_topic1) { Fabricate(:discourse_events_event_topic, event: event1, topic: topic1) }
  fab!(:event2) do
    Fabricate(:discourse_events_event, start_time: 2.hours.from_now, name: "Tim's party")
  end

  before do
    freeze_time
    sign_in(user)
  end

  describe "#index" do
    it "returns events" do
      get "/admin/plugins/events/event.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["events"].size).to eq(2)

      event = response.parsed_body["events"].find { |e| e["id"] == event1.id }
      expect(event["start_time"].to_datetime).to eq_time(event1.start_time.to_datetime)
      expect(event["name"]).to eq(event1.name)
      expect(event["topic_ids"]).to eq([topic1.id])
    end

    it "returns params" do
      get "/admin/plugins/events/event.json",
          params: {
            page: 1,
            filter: "connected",
            order: "name",
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body["page"]).to eq(1)
      expect(response.parsed_body["filter"]).to eq("connected")
      expect(response.parsed_body["order"]).to eq("name")
    end

    it "returns topic counts" do
      get "/admin/plugins/events/event.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["with_topics_count"]).to eq(1)
      expect(response.parsed_body["without_topics_count"]).to eq(1)
    end

    it "orders events by start time by default" do
      get "/admin/plugins/events/event.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["events"].first["id"]).to eq(event2.id)
    end

    it "orders events by name" do
      get "/admin/plugins/events/event.json", params: { order: "name", asc: true }

      expect(response.status).to eq(200)
      expect(response.parsed_body["events"].size).to eq(2)
      expect(response.parsed_body["events"].first["id"]).to eq(event1.id)
    end

    it "filters events connected to topics" do
      get "/admin/plugins/events/event.json", params: { filter: "connected" }

      expect(response.status).to eq(200)
      expect(response.parsed_body["events"].size).to eq(1)
      expect(response.parsed_body["events"].first["id"]).to eq(event1.id)
    end

    it "filters events unconnected to topics" do
      get "/admin/plugins/events/event.json", params: { filter: "unconnected" }

      expect(response.status).to eq(200)
      expect(response.parsed_body["events"].size).to eq(1)
      expect(response.parsed_body["events"].first["id"]).to eq(event2.id)
    end

    context "with event series" do
      fab!(:event3) do
        Fabricate(:discourse_events_event, series_id: "ABC", start_time: 2.days.from_now)
      end
      fab!(:event4) do
        Fabricate(:discourse_events_event, series_id: "ABC", start_time: 6.days.from_now)
      end

      it "lists one event from the series" do
        get "/admin/plugins/events/event.json"

        expect(response.status).to eq(200)
        expect(response.parsed_body["events"].map { |e| e["id"] }).to include(event3.id)
        expect(response.parsed_body["events"].map { |e| e["id"] }).not_to include(event4.id)
      end

      it "lists the next event in the series" do
        event3.start_time = 2.days.ago
        event3.save!

        get "/admin/plugins/events/event.json"

        expect(response.status).to eq(200)
        expect(response.parsed_body["events"].map { |e| e["id"] }).not_to include(event3.id)
        expect(response.parsed_body["events"].map { |e| e["id"] }).to include(event4.id)
      end
    end
  end

  describe "#destroy" do
    context "with a subscription" do
      before { enable_subscription(:business) }

      context("when destroying") do
        it "destroys events" do
          topic_id = topic1.id
          post_id = post1.id
          event_id = event1.id

          delete "/admin/plugins/events/event.json",
                 params: {
                   event_ids: [event_id],
                   target: "events_only",
                 }

          expect(response.status).to eq(200)
          expect(response.parsed_body["destroyed_topics_event_ids"].blank?).to eq(true)
          expect(response.parsed_body["destroyed_event_ids"]).to eq([event_id])

          expect(DiscourseEvents::Event.exists?(event_id)).to eq(false)
          expect(Topic.exists?(topic_id)).to eq(true)
          expect(Post.exists?(post_id)).to eq(true)
        end

        it "destroys topics and posts associated with events if requested" do
          topic_id = topic1.id
          post_id = post1.id
          event_id = event1.id

          delete "/admin/plugins/events/event.json",
                 params: {
                   event_ids: [event_id],
                   target: "events_and_topics",
                 }

          expect(response.status).to eq(200)
          expect(response.parsed_body["destroyed_topics_event_ids"]).to eq([event_id])
          expect(response.parsed_body["destroyed_event_ids"]).to eq([event_id])

          expect(DiscourseEvents::Event.exists?(event_id)).to eq(false)
          expect(Topic.exists?(topic_id)).to eq(false)
          expect(Post.exists?(post_id)).to eq(false)
        end

        it "destroys topics associated with events if requested" do
          topic_id = topic1.id
          post_id = post1.id
          event_id = event1.id
          event_topic_id = event_topic1.id

          delete "/admin/plugins/events/event.json",
                 params: {
                   event_ids: [event_id],
                   target: "topics_only",
                 }

          expect(response.status).to eq(200)
          expect(response.parsed_body["destroyed_topics_event_ids"]).to eq([event_id])
          expect(response.parsed_body["destroyed_event_ids"].blank?).to be(true)

          expect(DiscourseEvents::Event.exists?(event_id)).to eq(true)
          expect(DiscourseEvents::EventTopic.exists?(event_topic_id)).to eq(false)
          expect(Topic.exists?(topic_id)).to eq(false)
          expect(Post.exists?(post_id)).to eq(false)
        end
      end
    end
  end
end
