# frozen_string_literal: true

module DiscourseEvents
  class EventSource < ActiveRecord::Base
    self.table_name = "discourse_events_event_sources"

    belongs_to :source, foreign_key: "source_id", class_name: "DiscourseEvents::Source"
    belongs_to :event, foreign_key: "event_id", class_name: "DiscourseEvents::Event"
    
  end
end

# == Schema Information
#
# Table name: discourse_events_event_connections
#
#  id            :bigint           not null, primary key
#  event_id      :bigint           not null
#  source_id     :bigint           not null
#  uid           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  discourse_events_event_connections_event  (event_id)
#
# Foreign Keys
#
#  fk_rails_...  (connection_id => discourse_events_connections.id)
#  fk_rails_...  (event_id => discourse_events_events.id)
#
