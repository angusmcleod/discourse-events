# frozen_string_literal: true

module DiscourseEvents
  class SubscriptionController < AdminController
    def index
      manager = SubscriptionManager.new
      manager.setup(update: !!params[:update_from_remote])

      render_json_dump(
        subscribed: manager.subscribed?,
        product: manager.product.to_s
      )
    end
  end
end
