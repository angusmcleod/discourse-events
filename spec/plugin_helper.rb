# frozen_string_literal: true

require_relative "./support/omnievent.rb"

RSpec.configure { |config| config.include OmniEvent }

def enable_subscription(type)
  DiscourseEvents::SubscriptionManager.any_instance.stubs(:subscribed?).returns(true)
  DiscourseEvents::SubscriptionManager.any_instance.stubs(:product).returns(type)
end

def disable_subscriptions
  DiscourseEvents::SubscriptionManager.any_instance.stubs(:subscribed?).returns(false)
  DiscourseEvents::SubscriptionManager.any_instance.stubs(:product).returns(nil)
end
