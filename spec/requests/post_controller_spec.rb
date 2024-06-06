# frozen_string_literal: true
describe PostsController do
  let!(:user1) { Fabricate(:user, refresh_auto_groups: true) }
  let!(:user2) { Fabricate(:user, refresh_auto_groups: true) }
  let!(:category) do
    category = Fabricate(:category)
    category.custom_fields["events_enabled"] = true
    category.save_custom_fields(true)
    category
  end

  def create_params
    {
      title: "Let us test events together!",
      raw: "This is an interesting test events post with some content.",
      category: category.id,
    }
  end

  def find_topic(response)
    Topic.find(response.parsed_body["topic_id"])
  end

  before { sign_in(user1) }

  describe "when creating a post with an event" do
    it "creates an event" do
      post "/posts.json", params: create_params.merge(event: { start: "2017-09-18T16:00:00+08:00" })
      expect(response.status).to eq(200)
      expect(find_topic(response).has_event?).to eq(true)
    end

    it "doesn't create the event without the start value" do
      post "/posts.json", params: create_params.merge(event: { start: nil })
      expect(response.status).to eq(200)
      expect(find_topic(response).has_event?).to eq(false)
    end
  end

  describe "when creating a post with event rsvp" do
    it "converts the event going usernames to user ids while storing" do
      event = {
        start: "2017-09-18T16:00:00+08:00",
        post_number: 1,
        rsvp: true,
        going: [user1.username, user2.username],
      }
      post "/posts.json", params: create_params.merge(event: event)
      expect(response.status).to eq(200)
      expect(find_topic(response).event_going.sort).to eq([user1.id, user2.id].sort)
    end
  end
end
