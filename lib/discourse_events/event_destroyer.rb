# frozen_string_literal: true

module DiscourseEvents
  class EventDestroyer
    def self.perform(user: nil, event_ids: [], target: nil)
      return if user.blank? || event_ids.blank? || target.blank?

      result = { destroyed_event_ids: [], destroyed_topics_event_ids: [] }

      ActiveRecord::Base.transaction do
        events = Event.where(id: event_ids)

        if target === "events_and_topics" || target === "topics_only"
          event_topics = {}

          events
            .includes(:event_topics)
            .each do |event|
              event.event_topics.each do |et|
                destroyer = PostDestroyer.new(user, et.topic.first_post)
                destroyer.destroy
                event_topics[et.id] ||= et
              end

              result[:destroyed_topics_event_ids] << event.id
            end

          DiscourseEvents::EventTopic.where(id: event_topics.keys).delete_all
        end

        if target === "events_only" || target === "events_and_topics"
          destroyed_events = events.destroy_all
          result[:destroyed_event_ids] += destroyed_events.map(&:id)

          series_events = destroyed_events.select { |e| e.series_id.present? }
          if SiteSetting.events_one_event_per_series
            destroyed_series_events =
              Event
                .where.not(id: series_events.map(&:id))
                .where(series_id: series_events.map(&:series_id))
                .destroy_all
            result[:destroyed_event_ids] += destroyed_series_events.map(&:id)
          end
        end
      end

      result
    end
  end
end
