# frozen_string_literal: true

module DiscourseEvents
  class AdminController < ::Admin::AdminController
    include DiscourseEvents::Subscription

    before_action :ensure_admin
    before_action :ensure_subscribed, except: [:index]

    requires_plugin DiscourseEvents::PLUGIN_NAME

    def index
    end

    def ensure_subscribed
      raise Discourse::InvalidAccess.new unless subscribed?
    end
  end
end
