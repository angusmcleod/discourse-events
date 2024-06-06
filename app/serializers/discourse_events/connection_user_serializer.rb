# frozen_string_literal: true

module DiscourseEvents
  class ConnectionUserSerializer < ApplicationSerializer
    attributes :id, :username
  end
end
