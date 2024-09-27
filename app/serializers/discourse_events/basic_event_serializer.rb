# frozen_string_literal: true

module DiscourseEvents
  class BasicEventSerializer < ApplicationSerializer
    attributes :id, :start_time, :name
  end
end
