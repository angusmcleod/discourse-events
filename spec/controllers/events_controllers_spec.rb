require 'rails_helper'

describe PostsController do
  let!(:user) { log_in }
  let!(:event_category) { cat = Fabricate(:category) 
                          cat.custom_fields['events_enabled'] = true
                          cat.save
                          cat }
  let!(:event_topic) {Fabricate(:topic, category: event_category)}
  let!(:event_start) { '2017-09-18T16:00:00+08:00' } # 1505721600
  let!(:event_end)  { '2017-09-18T17:00:00+08:00' } # 1505725200
  let!(:topic_title) { 'lets test events' }
  let!(:topic_body) { 'interesting test events post' }

  describe "event creation" do
    it "creates an event" do
      post :create, params: { title: topic_title, raw: topic_body,  event: {'start' => event_start}, topic_id: event_topic.id }, format: :json
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(Topic.find(event_topic.id).has_event?).to be_truthy
    end

    it "doesn't create the event without the start value" do
      post :create, params: { title: topic_title, raw: topic_body,  event: {'start' => nil}, topic_id: event_topic.id }, format: :json
      expect(response).to be_successful
      expect(Topic.find(event_topic.id).has_event?).not_to be_truthy
    end

  end

end

describe "event rsvp" , :type => :request do
  let(:event_category) { cat = Fabricate(:category)
                          cat.custom_fields['events_enabled'] = true
                          cat.save
                          cat }
  let(:event_topic) {Fabricate(:topic, category: event_category)}
  let(:topic_body) { 'interesting test events post' }
  let(:topic_title) { 'lets test events' }
  let(:event_start) { '2017-09-18T16:00:00+08:00' } # 1505721600
  let(:rsvp_user_1) {Fabricate(:user)}
  let(:rsvp_user_2) {Fabricate(:user)}

  before do
    sign_in Fabricate(:user)
    headers = {
      "ACCEPT" => "application/json",     # This is what Rails 4 accepts
      "HTTP_ACCEPT" => "application/json" # This is what Rails 3 accepts
    }
    post "/posts", params: { title: topic_title, raw: topic_body,  event: {'start' => event_start, 'post_number' => 1,'rsvp'=> true, 'going'=>[rsvp_user_1.username, rsvp_user_2.username]}, topic_id: event_topic.id }, :headers => headers

  end

  it "converts the usernames to user ids while storing" do
      expect(response).to be_successful
      expect(event_topic.event_going).to eq([rsvp_user_1.id, rsvp_user_2.id])

  end

  it "converts the user ids to usernames while sending to the client" do 
    get "/t/#{event_topic.id}.json"
    expect(response).to be_successful
    topic = JSON.parse(response.body)
    expect(topic['event_going']).to eq([rsvp_user_1.username,rsvp_user_2.username ])
  end

end