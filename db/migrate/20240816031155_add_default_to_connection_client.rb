# frozen_string_literal: true
class AddDefaultToConnectionClient < ActiveRecord::Migration[7.1]
  def change
    change_column_default :discourse_events_connections, :client, "events"
  end
end
