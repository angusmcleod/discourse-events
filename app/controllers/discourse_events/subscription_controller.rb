# frozen_string_literal: true

module DiscourseEvents
  class SubscriptionController < AdminController
    def index
      subscription_manager.setup(update: !!params[:update_from_remote])

      render_json_dump(
        subscribed: subscribed?,
        authorized: authorized?,
        supplier_id: supplier&.id,
        product: subscription_manager.product.to_s,
        features: subscription_manager.features,
      )
    end
  end
end
