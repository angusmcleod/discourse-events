# frozen_string_literal: true

module DiscourseEvents
  class ConnectionFilter < ActiveRecord::Base
    self.table_name = 'discourse_events_connection_filters'

    belongs_to :connection, foreign_key: 'connection_id', class_name: 'DiscourseEvents::Connection'

    enum :query_column, %i(name), prefix: true

    OPERATORS = {
      name: 'ILIKE'
    }

    validate :query_value_format

    def sql_value
      if sql_operator === 'ILIKE'
        "%#{self.query_value}%"
      end
    end

    def sql_operator
      OPERATORS[self.query_column.to_sym]
    end

    def sql_column
      self.query_column.to_s
    end

    def query_value_format
      if self.query_column === :name
        errors.add(:query_value, 'invalid') unless self.query_value =~ /./
      end
    end
  end
end

# == Schema Information
#
# Table name: discourse_events_connection_filters
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
