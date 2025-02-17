# frozen_string_literal: true

describe DiscourseEvents::ApiKeysController do
  fab!(:user) { Fabricate(:user, admin: true) }

  before { sign_in(user) }

  it "returns an api key" do
    get "/discourse-events/api-keys.json"
    expect(response.status).to eq(200)
    expect(response.parsed_body["api_keys"].first["key"]).to be_present
    expect(response.parsed_body["api_keys"].first["client_id"]).to be_present
  end
end
