require 'rails_helper'

describe PostsController do
  let!(:user) { log_in }
  let(:events_category) {
    c = Fabricate(:category)
    c.custom_fields['events_enabled'] = true
    c.save
    c }
  let!(:topic) { Fabricate(:topic, category: events_category) }
  let!(:title) { 'Testing Events Plugin' }
  let!(:event1) do
    { 'start' => '2017-09-18T16:00:00+08:00', # 1505721600
      'end' => '2017-09-18T17:00:00+08:00' } # 1505725200
  end

  describe 'when creating an event topic' do
    it 'works' do
      post :create, params: { title: title, raw: 'New event', event: event1, topic_id: topic.id}, format: :json
      expect(response).to be_success
      json = ::JSON.parse(response.body)

      expect(TopicCustomField.find_by(
        topic_id: json['topic_id'],
        name: 'event_start'
      ).value).to eq('1505721600')

      expect(TopicCustomField.find_by(
        topic_id: json['topic_id'],
        name: 'event_end'
      ).value).to eq('1505725200')
    end
  end

  describe 'when an event topic has no start and end' do
    let!(:topic) { Fabricate(:topic, user: user, custom_fields: { event_start: nil, event_end: nil }, category: events_category) }
    let!(:post) { Fabricate(:post, user: user, topic_id: topic.id, post_number: 1) }

    it 'allows the first post to be edited' do
      put :update, params: { id: post.id, post: { raw: 'edited body', edit_reason: 'typo' } }, format: :json
      expect(response).to be_success
    end
  end
end

describe TopicsController do
  let!(:title) { 'Testing Events Plugin' }
  let(:events_category) {
    c = Fabricate(:category)
    c.custom_fields['events_enabled'] = true
    c.save
    c }
  let!(:event1) do
    { 'start' => '2017-09-18T16:00:00+08:00', # 1505721600
      'end' => '2017-09-18T17:00:00+08:00' } # 1505725200
  end
  let!(:event2) do
    { 'start' => '2017-09-19T18:00:00+08:00', # 1505815200
      'end' => '2017-09-19T19:00:00+08:00' } # 1505818800
  end

  describe 'when an event topic has an event' do
    let!(:user) { log_in(:user) }
    let!(:topic) do
      Fabricate(:topic, user: user, custom_fields: { event: event1 }, category: events_category)
    end

    before do
      Fabricate(:post, topic: topic, user: user)
      Guardian.any_instance.expects(:can_edit?).with(topic).returns(true)
    end

    it 'works' do
      put :update, params: { topic_id: topic.id, slug: topic.title, event: event2 }, format: :json
      expect(response).to be_success
      json = ::JSON.parse(response.body)
      expect(TopicCustomField.find_by(
        topic_id: json['basic_topic']['id'],
        name: 'event_start'
      ).value).to eq('1505815200')
      expect(TopicCustomField.find_by(
        topic_id: json['basic_topic']['id'],
        name: 'event_end'
      ).value).to eq('1505818800')
    end
  end
end
