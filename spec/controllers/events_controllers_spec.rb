require "rails_helper"

describe PostsController do
  let!(:user) { log_in }
  let!(:title) { "Testing Events Plugin" }
  let!(:event1) { {"start"=>"2017-09-18T16:00:00+08:00", "end"=>"2017-09-18T17:00:00+08:00"} } # 1505721600 to 1505725200

  describe "post events" do

    before do
      SiteSetting.location_geocoding_provider = :nominatim

      stub_request(:get, "https://nominatim.openstreetmap.org/search?accept-language=en&addressdetails=1&format=json&q=10%20Downing%20Street").
      with(headers: {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: "", headers: {})
    end

    it "works" do
      xhr :post, :create, title: title, raw: "New event", event: event1
      expect(response).to be_success
      json = ::JSON.parse(response.body)
      expect(TopicCustomField.find_by(topic_id: json['topic_id'], name: 'event_start').value).to eq("1505721600")
      expect(TopicCustomField.find_by(topic_id: json['topic_id'], name: 'event_end').value).to eq("1505725200")
    end
  end
end

describe TopicsController do
  let!(:title) { "Testing Events Plugin" }
  let!(:event1) { {"start"=>"2017-09-18T16:00:00+08:00", "end"=>"2017-09-18T17:00:00+08:00"} } # 1505721600 to 1505725200
  let!(:event2) { {"start"=>"2017-09-19T18:00:00+08:00", "end"=>"2017-09-19T19:00:00+08:00"} } # 1505815200 to 1505818800

  describe "update events" do
    let!(:user) { log_in(:user) }
    let!(:topic) { Fabricate(:topic, user: user, custom_fields: { event: event1 }) }

    before do
      Fabricate(:post, topic: topic, user: user)
      Guardian.any_instance.expects(:can_edit?).with(topic).returns(true)
    end

    it "works" do
      xhr :put, :update, topic_id: topic.id, slug: topic.title, event: event2
      expect(response).to be_success
      json = ::JSON.parse(response.body)
      expect(TopicCustomField.find_by(topic_id: json['basic_topic']['id'], name: 'event_start').value).to eq("1505815200")
      expect(TopicCustomField.find_by(topic_id: json['basic_topic']['id'], name: 'event_end').value).to eq("1505818800")
    end
  end
end
