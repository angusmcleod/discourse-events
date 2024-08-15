# frozen_string_literal: true

module DiscourseEvents
  class Filter < ActiveRecord::Base
    self.table_name = "discourse_events_filters"

    MODEL_TYPES = %w[DiscourseEvents::Connection]

    belongs_to :model, polymorphic: true

    enum :query_column, %i[name], prefix: true
    enum :query_operator, %i[like], prefix: true

    OPERATORS = { like: "ILIKE" }

    validate :query_value_format
    validates :model_type, inclusion: { in: MODEL_TYPES }

    def sql_value
      "%#{self.query_value}%" if query_operator_like?
    end

    def sql_operator
      OPERATORS[self.query_operator.to_sym]
    end

    def sql_column
      self.query_column.to_s
    end

    def query_value_format
      if self.query_column === :name
        errors.add(:query_value, "invalid") unless self.query_value =~ /./
      end
    end
  end
end

# == Schema Information
#
# Table name: discourse_events_filters
#
#  id            :bigint           not null, primary key
#  connection_id :bigint           not null
#  query_column  :integer
#  query_value   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  idx_events_connection_filter_column_value  (query_column,query_value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (connection_id => discourse_events_connections.id)
#
