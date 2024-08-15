# frozen_string_literal: true

module DiscourseEvents
  class SourceSerializer < ApplicationSerializer
    attributes :id, :name, :provider_id, :source_options

    has_many :filters, serializer: FilterSerializer, embed: :objects

    def source_options
      object.source_options_hash
    end
  end
end
