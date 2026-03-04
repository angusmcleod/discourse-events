# frozen_string_literal: true

module DiscourseEvents
  class SubscriptionController < AdminController
    def index
      render_json_dump(
        subscribed: true,
        authorized: true,
        supplier_id: nil,
        product: subscription_manager.product.to_s,
        features: subscription_manager.features,
      )
    end
  end
end
