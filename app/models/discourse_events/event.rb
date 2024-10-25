# frozen_string_literal: true

module DiscourseEvents
  class Event < ActiveRecord::Base
    self.table_name = "discourse_events_events"
    self.ignored_columns += %i[uid source_id provider_id]

    has_many :event_connections,
             foreign_key: "event_id",
             class_name: "DiscourseEvents::EventConnection",
             dependent: :destroy
    has_many :connections, through: :event_connections, source: :connection
    has_many :topics, through: :event_connections

    has_many :event_sources,
             foreign_key: "event_id",
             class_name: "DiscourseEvents::EventSource",
             dependent: :destroy
    has_many :sources, through: :event_sources, source: :source

    has_many :series_events,
             primary_key: "series_id",
             foreign_key: "series_id",
             class_name: "DiscourseEvents::EventConnection"
    has_many :series_events_topics, through: :series_events, source: :topic

    validates :status,
              inclusion: {
                in: %w[draft published cancelled],
                message: "%{value} is not a valid event status",
              }
  end
end

# == Schema Information
#
# Table name: discourse_events_events
#
#  id            :bigint           not null, primary key
#  start_time    :datetime         not null
#  end_time      :datetime
#  name          :string
#  description   :string
#  status        :string           default("published")
#  taxonomy      :string
#  url           :string
#  series_id     :string
#  occurrence_id :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => discourse_events_providers.id)
#  fk_rails_...  (source_id => discourse_events_sources.id)
#
