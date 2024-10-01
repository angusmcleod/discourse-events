# frozen_string_literal: true

module DiscourseEvents
  class SourceSerializer < ApplicationSerializer
    attributes :id,
               :name,
               :provider_id,
               :source_options,
               :import_type,
               :import_period,
               :sync_type,
               :user_id,
               :category_id,
               :client,
               :ready

    has_many :filters, serializer: FilterSerializer, embed: :objects

    def source_options
      object.source_options_hash
    end

    def ready
      object.ready?
    end

    def import_period
      object.import_period || 0
    end
  end
end
