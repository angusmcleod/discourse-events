# frozen_string_literal: true

module DiscourseEvents
  class AdminController < ::Admin::AdminController
    before_action :ensure_admin

    def index
    end
  end
end
