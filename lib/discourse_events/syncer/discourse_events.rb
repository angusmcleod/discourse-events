# frozen_string_literal: true

module DiscourseEvents
  class DiscourseEventsSyncer < DiscourseEvents::Syncer
    def ready?
      source.category.events_enabled
    end

    def create_topic(event)
      post =
        create_post(
          event,
          featured_link: event.url,
          custom_fields: {
            event_start: event.start_time.to_i,
            event_end: event.end_time.to_i,
          },
        )
      post.topic
    end

    def connect_topic(topic, event)
      return false if topic.has_event? || topic.first_post.blank?
      update_topic(topic, event, add_raw: true)
    end

    def update_topic(topic, event, add_raw: false)
      post = topic.first_post

      # No validations or callbacks can be triggered when updating this data
      topic.update_columns(title: event.name, fancy_title: nil, slug: nil, featured_link: event.url)
      post.update_columns(raw: post_raw(event, post: post, add_raw: add_raw))
      topic.custom_fields["event_start"] = event.start_time.to_i
      topic.custom_fields["event_end"] = event.end_time.to_i
      topic.save_custom_fields(true)

      post.trigger_post_process(bypass_bump: true, priority: :low)

      topic
    end

    def post_raw(event, post: nil, add_raw: false)
      raw = event.description.present? ? event.description : event.name
      raw += "\n\n#{post.raw}" if post && add_raw
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
