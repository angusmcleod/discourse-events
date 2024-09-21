# frozen_string_literal: true

module DiscourseEvents
  class AdminController < ::Admin::AdminController
    before_action :ensure_admin
    before_action :ensure_subscribed, except: [:index]

    requires_plugin DiscourseEvents::PLUGIN_NAME

    def index
    end

    def ensure_subscribed
      raise DiscourseEvents::NotSubscribed.new unless subscription.subscribed?
    end

    def subscription
      @subscription ||= SubscriptionManager.new
    end
  end
end
