# frozen_string_literal: true

describe DiscourseEvents::AdminController do
  fab!(:user)
  fab!(:moderator) { Fabricate(:user, moderator: true) }
  fab!(:admin) { Fabricate(:user, admin: true) }

  it "prevents access by non-admins" do
    sign_in(user)
    get "/admin/plugins/events.json"
    expect(response.status).to eq(404)
  end

  it "allows access by admins" do
    sign_in(admin)
    get "/admin/plugins/events.json"
    expect(response.status).to eq(204)
  end
end
