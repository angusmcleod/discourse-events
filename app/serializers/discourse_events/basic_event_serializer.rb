# frozen_string_literal: true

module DiscourseEvents
  class BasicEventSerializer < ApplicationSerializer
    attributes :id,
               :start_time,
               :end_time,
               :name,
               :description,
               :status,
               :url,
               :created_at,
               :updated_at
  end
end
