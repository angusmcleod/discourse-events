# frozen_string_literal: true

module DiscourseEvents
  class SourceSerializer < ApplicationSerializer
    attributes :id, :name, :provider_id, :source_options, :from_time, :to_time

    def source_options
      object.source_options_hash
    end
  end
end
