# frozen_string_literal: true
class RemoveUnusedSourceColumns < ActiveRecord::Migration[7.1]
  def change
    remove_column :discourse_events_sources, :name
    remove_column :discourse_events_sources, :from_time
    remove_column :discourse_events_sources, :to_time
    remove_column :discourse_events_sources, :status
    remove_column :discourse_events_sources, :taxonomy
    remove_column :discourse_events_sources, :sync_type
  end
end
