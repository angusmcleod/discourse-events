# frozen_string_literal: true

module DiscourseEvents
  class AdminController < ::Admin::AdminController
    include DiscourseEvents::Subscription

    before_action :ensure_admin

    requires_plugin DiscourseEvents::PLUGIN_NAME

    def index
    end
  end
end
