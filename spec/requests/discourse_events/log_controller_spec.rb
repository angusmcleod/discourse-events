# frozen_string_literal: true

describe DiscourseEvents::LogController do
  fab!(:log) { Fabricate(:discourse_events_log) }
  fab!(:user) { Fabricate(:user, admin: true) }

  before do
    sign_in(user)
  end

  it "lists logs" do
    get "/admin/events/log.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body['logs'].first['id']).to eq(log.id)
  end
end
