# frozen_string_literal: true

describe DiscourseEvents::SubscriptionController do
  fab!(:admin_user) { Fabricate(:user, admin: true) }

  context "with an admin" do
    before { sign_in(admin_user) }

    context "without a subscription" do
      before { disable_subscriptions }

      it "returns the right subscription details" do
        get "/admin/plugins/events/subscription.json"
        expect(response.parsed_body["subscribed"]).to eq(false)
        expect(response.parsed_body["product"]).to eq("")
      end
    end

    context "with a subscription" do
      before { enable_subscription("business") }

      it "returns the right subscription details" do
        get "/admin/plugins/events/subscription.json"
        expect(response.parsed_body["subscribed"]).to eq(true)
        expect(response.parsed_body["product"]).to eq("business")
      end
    end
  end
end
