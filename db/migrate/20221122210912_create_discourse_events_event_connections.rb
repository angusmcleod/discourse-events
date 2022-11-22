class CreateDiscourseEventsEventConnections < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_events_event_connections do |t|
      t.references :event, null: false, index: { name: "discourse_events_event_connections_event" }, foreign_key: { to_table: :discourse_events_events }
      t.references :connection, null: false, index: false, foreign_key: { to_table: :discourse_events_connections }
      t.references :topic, index: false
      t.references :post, index: false
      t.string     :series_id
      t.string     :client

      t.timestamps
    end
  end
end
