# frozen_string_literal: true

describe DiscourseEvents::EventController do
  fab!(:connection) { Fabricate(:discourse_events_connection) }
  fab!(:event) { Fabricate(:discourse_events_event) }
  fab!(:user) { Fabricate(:user, admin: true) }

  before { sign_in(user) }

  it "lists events" do
    get "/admin/plugins/events/event.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["events"].first["id"]).to eq(event.id)
  end

  context "with a subscription" do
    before { enable_subscription(:business) }

    context("when destroying") do
      fab!(:topic)
      fab!(:post) { Fabricate(:post, topic: topic, user: user, raw: event.description) }
      fab!(:event_connection) do
        Fabricate(:discourse_events_event_connection, event: event, topic: topic)
      end

      it "destroys events" do
        topic_id = topic.id
        post_id = post.id
        event_id = event.id

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
        topic_id = topic.id
        post_id = post.id
        event_id = event.id

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
        topic_id = topic.id
        post_id = post.id
        event_id = event.id
        event_connection_id = event_connection.id

        delete "/admin/plugins/events/event.json",
               params: {
                 event_ids: [event_id],
                 target: "topics_only",
               }

        expect(response.status).to eq(200)
        expect(response.parsed_body["destroyed_topics_event_ids"]).to eq([event_id])
        expect(response.parsed_body["destroyed_event_ids"].blank?).to be(true)

        expect(DiscourseEvents::Event.exists?(event_id)).to eq(true)
        expect(DiscourseEvents::EventConnection.exists?(event_connection_id)).to eq(false)
        expect(Topic.exists?(topic_id)).to eq(false)
        expect(Post.exists?(post_id)).to eq(false)
      end
    end

    context "when connecting a topic" do
      let!(:topic) { Fabricate(:topic) }
      let!(:first_post) { Fabricate(:post, topic: topic) }

      shared_examples "connects topics" do
        it "connects a topic" do
          post "/admin/plugins/events/event/connect.json",
               params: {
                 topic_id: topic.id,
                 event_id: event.id,
                 client: client,
               }
          expect(response.status).to eq(200)
          expect(response.parsed_body["success"]).to eq("OK")
          expect(
            DiscourseEvents::EventConnection.exists?(
              topic_id: topic.id,
              event_id: event.id,
              client: client,
            ),
          ).to eq(true)
        end
      end

      context "with discourse_events" do
        let!(:client) { "discourse_events" }

        include_examples "connects topics"
      end

      context "with discourse_calendar" do
        let!(:client) { "discourse_calendar" }

        before do
          unless defined?(DiscoursePostEvent) == "constant"
            skip("Discourse Calendar is not installed")
          end

          SiteSetting.calendar_enabled = true
          SiteSetting.discourse_post_event_enabled = true
        end

        include_examples "connects topics"
      end
    end
  end
end
