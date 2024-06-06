# frozen_string_literal: true

module DiscourseEvents
  class LogSerializer < ApplicationSerializer
    attributes :id, :level, :context, :message, :created_at
  end
end
