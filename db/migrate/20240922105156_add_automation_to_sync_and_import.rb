# frozen_string_literal: true
class AddAutomationToSyncAndImport < ActiveRecord::Migration[7.1]
  def change
    add_column :discourse_events_sources, :import_period, :integer
    add_column :discourse_events_connections, :auto_sync, :boolean
  end
end
