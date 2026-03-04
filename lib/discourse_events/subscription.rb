# frozen_string_literal: true
module DiscourseEvents
  module Subscription
    def subscription_manager
      SubscriptionManager.new
    end
  end
end
