# frozen_string_literal: true

describe DiscourseEvents::RsvpController do
  fab!(:user)
  fab!(:topic)
  fab!(:post1) { Fabricate(:post, topic: topic) }

  def enable_rsvp
    SiteSetting.events_rsvp = true
    topic.custom_fields["event_rsvp"] = true
    topic.save_custom_fields(true)
  end

  describe "#update" do
    context "with rsvp enabled" do
      before { enable_rsvp }

      it "updates user rsvp" do
        put "/discourse-events/rsvp/update",
            params: {
              username: user.username,
              topic_id: topic.id,
              type: "going",
            }
        expect(response.status).to eq(200)
        expect(response.parsed_body["success"]).to eq("OK")
        expect(topic.reload.event_going).to include(user.id)
      end
    end
  end

  describe "#users" do
    fab!(:another_user) { Fabricate(:user) }

    context "with rsvp enabled" do
      before do
        topic.custom_fields["event_going"] = [user.id, another_user.id]
        enable_rsvp
      end

      it "lists users by rsvp type" do
        get "/discourse-events/rsvp/users", params: { type: "going", topic_id: topic.id }
        expect(response.status).to eq(200)
        expect(response.parsed_body["users"].map { |u| u["id"] }).to match_array(
          [user.id, another_user.id],
        )
      end
    end
  end
end
