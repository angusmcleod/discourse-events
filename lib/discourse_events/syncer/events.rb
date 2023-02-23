# frozen_string_literal: true

module DiscourseEvents
  class EventsSyncer < DiscourseEvents::Syncer
    def self.ready?
      true
    end

    def create_event_topic(event)
      post = create_event_post(event,
        featured_link: event.url,
        custom_fields: {
          "event_start": event.start_time.to_i,
          "event_end": event.end_time.to_i
        }
      )
      post.topic
    end

    def update_event_topic(topic, event)
      # No validations or callbacks can be triggered when updating this data
      topic.update_columns(
        title: event.name,
        fancy_title: nil,
        slug: nil,
        featured_link: event.url
      )
      topic.first_post.update_columns(raw: post_raw(event))
      topic.custom_fields["event_start"] = event.start_time.to_i
      topic.custom_fields["event_end"] = event.end_time.to_i
      topic.save_custom_fields(true)

      topic.first_post.trigger_post_process(bypass_bump: true, priority: :low)

      topic
    end

    def post_raw(event)
      raw = ""
      raw += "#{event.description}" if event.description.present?
      raw
    end
  end
end

# == Events Plugin Schema
#
# Table: topic_custom_fields
#
# Fields:
#  event_start        unix datetime
#  event_end          unix datetime
