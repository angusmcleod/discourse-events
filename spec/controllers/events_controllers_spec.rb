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