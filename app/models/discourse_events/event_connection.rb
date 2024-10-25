# frozen_string_literal: true

module DiscourseEvents
  class EventConnection < ActiveRecord::Base
    self.table_name = "discourse_events_event_connections"
    self.ignored_columns += [:post_id]

    belongs_to :connection, foreign_key: "connection_id", class_name: "DiscourseEvents::Connection"
    belongs_to :event, foreign_key: "event_id", class_name: "DiscourseEvents::Event"
    belongs_to :topic

    validates :client,
              inclusion: {
                in: Connection.client_names,
                message: "%{value} is not a valid connection client",
              }
  end
end

# == Schema Information
#
# Table name: discourse_events_event_connections
#
#  id            :bigint           not null, primary key
#  event_id      :bigint           not null
#  connection_id :bigint           not null
#  topic_id      :bigint
#  series_id     :string
#  client        :string
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
