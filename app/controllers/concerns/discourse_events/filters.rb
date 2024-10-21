# frozen_string_literal: true
module DiscourseEvents
  module Filters
    def valid_filters
    end

    def save_filters
      @errors ||= []
      saved_ids = []

      ActiveRecord::Base.transaction do
        valid_filters.each do |f|
          params = f.slice(:query_column, :query_operator, :query_value)

          if f[:id] === "new"
            begin
              filter =
                DiscourseEvents::Filter.create(
                  model_id: @model.id,
                  model_type: @model.class.name,
                  **params,
                )
            rescue => e
              raise ActiveRecord::Rollback
            end
          else
            filter = @model.filters.update(f[:id].to_i, params)
          end

          if filter.errors.any?
            @errors << filter.errors
            raise ActiveRecord::Rollback
          end

          saved_ids << filter.id
        end
      end

      @model.filters.where.not(id: saved_ids).destroy_all
    end
  end
end
