# frozen_string_literal: true

module DiscourseEvents
  class Event < ActiveRecord::Base
    self.table_name = "discourse_events_events"
    self.ignored_columns += %i[uid source_id provider_id]

    has_many :event_topics,
             foreign_key: "event_id",
             class_name: "DiscourseEvents::EventTopic",
             dependent: :destroy
    has_many :topics, through: :event_topics

    has_many :event_sources,
             foreign_key: "event_id",
             class_name: "DiscourseEvents::EventSource",
             dependent: :destroy
    has_many :sources, through: :event_sources, source: :source

    has_many :series_events,
             primary_key: "series_id",
             foreign_key: "series_id",
             class_name: "DiscourseEvents::EventTopic"
    has_many :series_topics, through: :series_events, source: :topic

    has_many :registrations,
             foreign_key: "event_id",
             class_name: "DiscourseEvents::EventRegistration",
             dependent: :destroy

    PAST_SERIES_EVENTS_SQL = (<<~SQL)
      DISTINCT ON (series_id) *
      FROM discourse_events_events
      WHERE series_id IS NOT NULL AND start_time < NOW()
      ORDER BY series_id, start_time DESC
    SQL

    FUTURE_SERIES_EVENTS_SQL = (<<~SQL)
      DISTINCT ON (series_id) *
      FROM discourse_events_events
      WHERE series_id IS NOT NULL AND start_time > NOW()
      ORDER BY series_id, start_time ASC
    SQL

    CURRENT_SERIES_EVENTS_SQL = (<<~SQL)
      DISTINCT ON (series_id) * FROM (
        (SELECT #{FUTURE_SERIES_EVENTS_SQL})
        UNION
        (SELECT #{PAST_SERIES_EVENTS_SQL})
      ) current_series_events
      ORDER BY series_id, start_time DESC
    SQL

    ONE_EVENT_PER_SERIES_SQL = (<<~SQL)
      (SELECT #{CURRENT_SERIES_EVENTS_SQL})
      UNION
      (SELECT * FROM discourse_events_events WHERE series_id IS NULL)
    SQL

    def featured_url
      if video_url
        video_url
      elsif url
        url
      else
        nil
      end
    end

    def self.events_sql
      if SiteSetting.events_one_event_per_series
        ONE_EVENT_PER_SERIES_SQL
      else
        "SELECT * FROM discourse_events_events"
      end
    end

    def self.list_sql(filter_sql: "")
      (<<~SQL)
        SELECT e.id,
               e.start_time,
               e.name,
               e.series_id, 
               array_remove(array_agg(et.topic_id), NULL) AS topic_ids,
               es.source_id,
               s.provider_id
        FROM (#{events_sql}) AS e
        LEFT JOIN discourse_events_event_topics et ON et.event_id = e.id
        LEFT JOIN discourse_events_event_sources es ON es.event_id = e.id
        LEFT JOIN discourse_events_sources s ON s.id = es.source_id
        #{filter_sql}
        GROUP BY e.id, e.start_time, e.name, e.series_id, es.source_id, s.provider_id
      SQL
    end
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
