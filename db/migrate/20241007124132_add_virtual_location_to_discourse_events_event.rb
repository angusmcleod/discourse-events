# frozen_string_literal: true
class AddVirtualLocationToDiscourseEventsEvent < ActiveRecord::Migration[7.1]
  def change
    add_column :discourse_events_events, :video_url, :string
  end
end
