# frozen_string_literal: true

module DiscourseEvents
  class FilterSerializer < ApplicationSerializer
    attributes :id, :query_column, :query_operator, :query_value
  end
end
