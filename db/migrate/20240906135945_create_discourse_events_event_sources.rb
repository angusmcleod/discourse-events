# frozen_string_literal: true
class CreateDiscourseEventsEventSources < ActiveRecord::Migration[7.1]
  def up
    create_table :discourse_events_event_sources do |t|
      t.string :uid, null: false
      t.references :source, index: true, foreign_key: { to_table: :discourse_events_sources }
      t.references :event, index: true, foreign_key: { to_table: :discourse_events_events }

      t.timestamps
    end

    execute "INSERT INTO discourse_events_event_sources (uid, source_id, event_id, created_at, updated_at)
             SELECT events.uid, events.source_id, events.id, events.created_at, events.updated_at
             FROM discourse_events_events events
             WHERE events.source_id IS NOT NULL"

    change_column_null :discourse_events_events, :uid, true
    remove_index :discourse_events_events, name: "discourse_events_event_id_index"
    remove_index :discourse_events_events, name: "index_discourse_events_events_on_provider_id"
    remove_index :discourse_events_events, name: "index_discourse_events_events_on_source_id"
  end

  def down
    change_column_null :discourse_events_events, :uid, false
    add_index :discourse_events_events,
              %i[uid provider_id],
              unique: true,
              name: "discourse_events_event_id_index",
              if_not_exists: true
    add_index :discourse_events_events,
              %i[provider_id],
              name: "index_discourse_events_events_on_provider_id",
              if_not_exists: true
    add_index :discourse_events_events,
              %i[source_id],
              name: "index_discourse_events_events_on_source_id",
              if_not_exists: true
  end
end
