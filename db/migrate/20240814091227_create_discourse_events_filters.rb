# frozen_string_literal: true
class CreateDiscourseEventsFilters < ActiveRecord::Migration[7.1]
  def up
    create_table :discourse_events_filters do |t|
      t.integer :model_id
      t.string :model_type
      t.integer :query_column
      t.integer :query_operator
      t.string :query_value

      t.timestamps
    end

    execute "INSERT INTO discourse_events_filters (model_id, model_type, query_column, query_operator, query_value, created_at, updated_at)
             SELECT cfs.id, 'DiscourseEvents::Connection', cfs.query_column, 0, cfs.query_value, cfs.created_at, cfs.updated_at
             FROM discourse_events_connection_filters cfs"

    add_index :discourse_events_filters,
              %i[query_column query_operator query_value],
              unique: true,
              name: :idx_events_filter_column_operator_value
  end

  def down
    remove_index :discourse_events_filters,
                 %i[query_column query_operator query_value],
                 name: :idx_events_filter_column_operator_value

    drop_table :discourse_events_filters
  end
end
