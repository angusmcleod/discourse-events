# frozen_string_literal: true
module DiscourseEvents
  module Filters
    def valid_filters
    end

    def save_filters
      return unless valid_filters.present?
      @errors ||= []
      saved_ids = []

      valid_filters.each do |f|
        params = f.slice(:query_column, :query_operator, :query_value)

        if f[:id] === "new"
          filter =
            DiscourseEvents::Filter.create(
              model_id: @model.id,
              model_type: @model.class.name,
              **params,
            )
        else
          filter = @model.filters.update(f[:id].to_i, params)
        end

        if filter.errors.any?
          @errors << filter.errors
          raise ActiveRecord::Rollback
        end

        saved_ids << filter.id
      end

      @model.filters.where.not(id: saved_ids).destroy_all
    end
  end
end
