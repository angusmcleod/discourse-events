# frozen_string_literal: true

describe DiscourseEvents::SubscriptionController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }

  context "with an admin" do
    before { sign_in(admin_user) }

    it "returns the right subscription details" do
      get "/admin/plugins/events/subscription.json"
      expect(response.parsed_body["subscribed"]).to eq(true)
      expect(response.parsed_body["authorized"]).to eq(true)
      expect(response.parsed_body["product"]).to eq("enterprise")
      expect(response.parsed_body["features"]).to be_present
    end
  end
end
