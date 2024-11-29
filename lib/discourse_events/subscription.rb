# frozen_string_literal: true
module DiscourseEvents
  module Subscription
    def authorized?
      supplier ? supplier.authorized? : false
    end

    def supplier_id
      supplier ? supplier.id : nil
    end

    def subscribed?
      subscription_manager.ready? && subscription_manager.subscribed?
    end

    def subscription
      subscription_manager.ready? && subscription_manager.subscription
    end

    def supplier
      subscription_manager.ready_to_setup? && subscription_manager.supplier
    end

    def subscription_manager
      @subscription ||= SubscriptionManager.new
    end
  end
end
