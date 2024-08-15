# frozen_string_literal: true

module DiscourseEvents
  class Filter < ActiveRecord::Base
    self.table_name = "discourse_events_filters"

    MODEL_TYPES = %w[DiscourseEvents::Connection DiscourseEvents::Source]

    belongs_to :model, polymorphic: true

    enum :query_column, %i[name start_time], prefix: true
    enum :query_operator, %i[like greater_than less_than], prefix: true

    OPERATORS = { like: "ILIKE", greater_than: ">", less_than: "<" }

    validate :query_value_format
    validates :model_type, inclusion: { in: MODEL_TYPES }

    def sql_value
      return "%#{self.query_value}%" if query_operator_like?
      self.query_value.to_s
    end

    def sql_operator
      OPERATORS[self.query_operator.to_sym]
    end

    def sql_column
      self.query_column.to_s
    end

    def query_value_format
      if self.query_column === :name
        errors.add(:query_value, "invalid") unless self.query_value =~ /[a-zA-Z0-9]/
      end
      if self.query_column === :start_time
        begin
          DateTime.parse self.query_value
        rescue ArgumentError
          errors.add(:query_value, "invalid")
        end
      end
    end
  end
end

# == Schema Information
#
# Table name: discourse_events_filters
#
#  id             :bigint           not null, primary key
#  model_id       :integer
#  model_type     :string
#  query_column   :integer
#  query_operator :integer
#  query_value    :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  idx_events_filter_column_operator_value  (query_column,query_operator,query_value) UNIQUE
#
