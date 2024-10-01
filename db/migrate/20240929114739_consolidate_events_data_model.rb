# frozen_string_literal: true
class ConsolidateEventsDataModel < ActiveRecord::Migration[7.1]
  def up
    add_column :discourse_events_sources, :import_type, :integer
    add_column :discourse_events_sources, :user_id, :integer
    add_column :discourse_events_sources, :category_id, :integer
    add_column :discourse_events_sources, :client, :string, default: "discourse_events"

    execute "
      UPDATE discourse_events_sources
      SET import_type = old.sync_type
      FROM discourse_events_sources old
      WHERE old.sync_type IS NOT NULL
    "

    execute "
      UPDATE discourse_events_sources s
      SET user_id = c.user_id,
          category_id = c.category_id,
          client = c.client
      FROM discourse_events_connections c
      WHERE s.id = c.source_id
    "

    execute "
      UPDATE discourse_events_filters
      SET model_id = c.source_id,
          model_type = 'DiscourseEvents::Source'
      FROM discourse_events_filters f
      LEFT JOIN discourse_events_connections c ON c.id = f.model_id
      WHERE f.model_type = 'DiscourseEvents::Connection'
    "

    create_table :discourse_events_event_topics do |t|
      t.references :event, index: true, foreign_key: { to_table: :discourse_events_events }
      t.references :topic, index: true
      t.string :series_id, index: true
      t.string :client

      t.timestamps
    end

    execute "
      INSERT INTO discourse_events_event_topics (topic_id, event_id, client, series_id)
      SELECT ec.topic_id, ec.event_id, ec.client, ec.series_id
      FROM discourse_events_event_connections ec
    "

    add_index :discourse_events_event_topics,
              %i[event_id topic_id],
              unique: true,
              name: "discourse_events_event_topics_index"
  end

  def down
    remove_column :discourse_events_sources, :user_id
    remove_column :discourse_events_sources, :category_id
    remove_column :discourse_events_sources, :client
    remove_column :discourse_events_sources, :import_type
  end
end
