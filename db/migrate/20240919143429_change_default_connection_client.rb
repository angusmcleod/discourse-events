# frozen_string_literal: true
class ChangeDefaultConnectionClient < ActiveRecord::Migration[7.1]
  def change
    change_column_default :discourse_events_connections, :client, "discourse_events"
    execute "UPDATE discourse_events_connections SET client = CASE WHEN client = 'discourse_events' THEN 'discourse_calendar' ELSE 'discourse_events' END"
  end
end
