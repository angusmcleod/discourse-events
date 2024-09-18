# frozen_string_literal: true
class AddSyncTypeToDiscourseEventsSource < ActiveRecord::Migration[7.1]
  def change
    add_column :discourse_events_sources,
               :sync_type,
               :integer,
               default: DiscourseEvents::Source.sync_types[:import]
  end
end
