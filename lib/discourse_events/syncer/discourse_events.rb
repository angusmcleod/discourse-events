# frozen_string_literal: true

module DiscourseEvents
  class Syncer::DiscourseEvents < Syncer
    def ready?
      source.category.events_enabled && super
    end

    def can_connect_topic?(topic, event)
      topic.event.blank?
    end

    def create_client_topic(event, topic_opts = {})
      post =
        create_post(
          event,
          topic_opts.merge(
            featured_link: event.featured_url,
            custom_fields: {
              event_start: event.start_time.to_i,
              event_end: event.end_time.to_i,
            },
          ),
        )
      post.topic
    end

    def update_client_topic(topic, event, add_raw: false)
      post = topic.first_post

      # No validations or callbacks can be triggered when updating this data
      topic.update_columns(
        title: event.name,
        fancy_title: nil,
        slug: nil,
        featured_link: event.featured_url,
      )
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

    def update_client_registrations(topic, event)
      confirmed_user_ids = []

      event.registrations.each do |registration|
        next unless registration.user && registration.confirmed?
        confirmed_user_ids << registration.user.id
      end

      if confirmed_user_ids.any?
        event_going = topic.event_going || []

        if !topic.event_going_max || event_going.length <= topic.event_going_max
          confirmed_user_ids.each do |user_id|
            event_going << user_id unless event_going.include?(user_id)
          end
        end

        topic.custom_fields["event_rsvp"] = true
        topic.custom_fields["event_going"] = event_going
        topic.save_custom_fields(true)
      end
    end
  end
end
