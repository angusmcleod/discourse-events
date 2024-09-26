# frozen_string_literal: true
module DiscourseEvents
  module Subscription
    def subscribed?
      subscription_manager.ready? && subscription_manager.subscribed?
    end

    def subscription
      subscription_manager.ready? && subscription_manager.subscription
    end

    def subscription_manager
      @subscription ||= SubscriptionManager.new
    end
  end
end
