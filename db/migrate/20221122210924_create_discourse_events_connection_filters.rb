class CreateDiscourseEventsConnectionFilters < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_events_connection_filters do |t|
      t.references :connection, null: false, index: false, foreign_key: { to_table: :discourse_events_connections }
      t.integer :query_column
      t.string :query_value

      t.timestamps
    end

    add_index :discourse_events_connection_filters, [:query_column, :query_value], unique: true, name: :idx_events_connection_filter_column_value
  end
end
