# frozen_string_literal: true

module DiscourseEvents
  class Syncer::DiscourseCalendar < Syncer
    STATUS_MAP = { confirmed: "going", declined: "not_going", tentative: "interested" }.as_json

    def ready?
      ::DiscourseEvents.discourse_post_event_ready? && super
    end

    def can_connect_topic?(topic, event)
      topic.first_post.event.blank?
    end

    def create_client_topic(event, topic_opts = {})
      post = create_post(event, topic_opts)
      post.topic
    end

    def update_client_topic(topic, event, add_raw: false)
      post = topic.first_post

      # No validations or callbacks can be triggered when updating this data
      topic.update_columns(title: event.name, fancy_title: nil, slug: nil)
      post.update_columns(raw: post_raw(event, post: post, add_raw: add_raw))

      if post.event
        org_params = { original_starts_at: event.start_time }
        org_params[:original_ends_at] = event.end_time if add_end_time(event)
        org_params[:url] = event.featured_url
        post.event.update_columns(org_params)

        params = { starts_at: event.start_time }
        params[:ends_at] = event.end_time if add_end_time(event)
        post.event.event_dates.first.update_columns(params)
      end
      post.trigger_post_process(bypass_bump: true, priority: :low)

      topic
    end

    def post_raw(event, post: nil, add_raw: false)
      raw_params = "start=\"#{event.start_time}\" status=\"public\""
      raw_params += " end=\"#{event.end_time}\"" if add_end_time(event)
      raw_params += " url=\"#{event.featured_url}\"" if event.featured_url

      raw = "[event #{raw_params}]\n[/event]"
      raw += "\n#{event.description}" if event.description.present?
      raw += "\n\n#{post.raw}" if post && add_raw
      raw
    end

    def add_end_time(event)
      event.end_time && event.end_time > event.start_time
    end

    def update_client_registrations(topic, event)
      post = topic.first_post

      event.registrations.each do |registration|
        next unless registration.user

        invitee =
          DiscoursePostEvent::Invitee.find_by(user_id: registration.user.id, post_id: post.id)
        status = invitee_status(registration.status)

        if invitee
          invitee.update_attendance!(status)
        else
          DiscoursePostEvent::Invitee.create_attendance!(registration.user.id, post.id, status)
        end
      end
    end

    def invitee_status(registration_status)
      return STATUS_MAP[registration_status] if STATUS_MAP[registration_status].present?
      DiscoursePostEvent::Invitee::UNKNOWN_ATTENDANCE
    end
  end
end

# == Discourse Events Plugin Schema
#
# Table: discourse_calendar_post_events
#
# Fields:
#  status       0
#  name         string
#
# Table: discourse_calendar_post_event_dates
#
# Fields:
#  event_id     integer
#  starts_at    datetime
#  ends_at      datetime
