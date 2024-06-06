# frozen_string_literal: true
describe TopicsController do
  let!(:user1) { Fabricate(:user, refresh_auto_groups: true) }
  let!(:user2) { Fabricate(:user, refresh_auto_groups: true) }
  let!(:category) { Fabricate(:category, custom_fields: { events_enabled: true }) }
  let!(:post) { Fabricate(:post, topic: Fabricate(:topic, category: category)) }
  let(:opts) do
    {
      event: {
        start: "2017-09-18T16:00:00+08:00",
        post_number: 1,
        rsvp: true,
        going: [user1.username, user2.username],
      },
    }
  end

  before do
    sign_in(user1)
    DiscourseEvents::EventCreator.new(post, opts, user1).create
  end

  it "sends event going users as usernames" do
    get "/t/#{post.topic.id}.json"
    expect(response.parsed_body["event"]["going"].sort).to eq([user1.username, user2.username].sort)
  end
end
