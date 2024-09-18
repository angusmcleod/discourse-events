# frozen_string_literal: true
class AddDeadlineToDiscourseEventsEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :discourse_events_events, :deadline, :boolean, default: false
  end
end
