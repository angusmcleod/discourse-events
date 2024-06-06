# frozen_string_literal: true
class CreateDiscourseEventsEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_events_events do |t|
      t.string :uid, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.string :name
      t.string :description
      t.string :status, default: "published"
      t.string :taxonomy
      t.string :url
      t.string :series_id
      t.string :occurrence_id
      t.references :source, index: true, foreign_key: { to_table: :discourse_events_sources }
      t.references :provider, index: true, foreign_key: { to_table: :discourse_events_providers }

      t.timestamps
    end

    add_index :discourse_events_events,
              %i[uid provider_id],
              unique: true,
              name: "discourse_events_event_id_index",
              if_not_exists: true
  end
end
