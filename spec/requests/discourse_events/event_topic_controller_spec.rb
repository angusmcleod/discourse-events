# frozen_string_literal: true

describe DiscourseEvents::EventTopicController do
  fab!(:user) { Fabricate(:user, admin: true) }
  fab!(:event) { Fabricate(:discourse_events_event) }

  before { sign_in(user) }

  describe "#connect" do
    context "when connecting a topic to an event" do
      let!(:topic) { Fabricate(:topic) }
      let!(:first_post) { Fabricate(:post, topic: topic) }

      shared_examples "connects event topics" do
        it "connects a topic" do
          post "/admin/plugins/events/event/topic/connect.json",
               params: {
                 topic_id: topic.id,
                 event_id: event.id,
                 client: client,
               }
          expect(response.status).to eq(200)
          expect(response.parsed_body["success"]).to eq("OK")
          expect(DiscourseEvents::EventTopic.exists?(topic_id: topic.id, event_id: event.id)).to eq(
            true,
          )
        end
      end

      context "with discourse_events" do
        let!(:client) { "discourse_events" }

        include_examples "connects event topics"
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

        include_examples "connects event topics"
      end
    end

    context "when creating a topic for an event" do
      context "with discourse_events" do
        let!(:client) { "discourse_events" }

        context "with a category id" do
          fab!(:category) { Fabricate(:category) }

          before do
            category.custom_fields["events_enabled"] = true
            category.save_custom_fields(true)
          end

          it "creates a topic" do
            post "/admin/plugins/events/event/topic/connect.json",
                 params: {
                   event_id: event.id,
                   client: client,
                   category_id: category.id,
                 }
            expect(response.status).to eq(200)
            expect(response.parsed_body["success"]).to eq("OK")
            expect(DiscourseEvents::EventTopic.exists?(event_id: event.id)).to eq(true)
          end
        end
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

        it "creates a topic" do
          post "/admin/plugins/events/event/topic/connect.json",
               params: {
                 event_id: event.id,
                 client: client,
               }
          expect(response.status).to eq(200)
          expect(response.parsed_body["success"]).to eq("OK")
          expect(DiscourseEvents::EventTopic.exists?(event_id: event.id)).to eq(true)
        end
      end
    end
  end

  describe "#update" do
    context "when updating a topic" do
      fab!(:topic) { Fabricate(:topic) }
      fab!(:first_post) { Fabricate(:post, topic: topic) }
      fab!(:event_topic) { Fabricate(:discourse_events_event_topic, event: event, topic: topic) }

      before do
        event.name = "Updated event name"
        event.save!
      end

      shared_examples "updates event topics" do
        it "updates a topic" do
          post "/admin/plugins/events/event/topic/update.json", params: { event_id: event.id }
          expect(response.status).to eq(200)
          expect(response.parsed_body["success"]).to eq("OK")
          expect(topic.reload.title).to eq("Updated event name")
        end
      end

      context "with discourse_events" do
        before do
          event_topic.client = "discourse_events"
          event_topic.save!
        end

        include_examples "updates event topics"
      end

      context "with discourse_calendar" do
        let!(:client) { "discourse_calendar" }

        before do
          unless defined?(DiscoursePostEvent) == "constant"
            skip("Discourse Calendar is not installed")
          end

          SiteSetting.calendar_enabled = true
          SiteSetting.discourse_post_event_enabled = true

          event_topic.client = "discourse_calendar"
          event_topic.save!
        end

        include_examples "updates event topics"
      end
    end
  end
end
