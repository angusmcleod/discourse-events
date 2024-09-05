# frozen_string_literal: true
class AddExternalIdToDiscourseEventsEventConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :discourse_events_event_connections, :external_id, :string
  end
end
