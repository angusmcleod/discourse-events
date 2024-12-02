# frozen_string_literal: true
class ChangeDiscourseEventsEventConnectionsConnectionNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :discourse_events_event_connections, :connection_id, true
  end
end
