# frozen_string_literal: true

module DiscourseEvents
  class DiscourseEventsSyncer < DiscourseEvents::Syncer
    def self.ready?
      defined?(DiscoursePostEvent) == 'constant' &&
        DiscoursePostEvent.class == Module &&
        ::SiteSetting.calendar_enabled &&
        ::SiteSetting.discourse_post_event_enabled
    end

    def create_event_topic(event)
      post = create_event_post(event)
      post.topic
    end

    def update_event_topic(topic, event)
      # No validations or callbacks can be triggered when updating this data
      topic.update_columns(title: event.name)
      topic.first_post.update_columns(raw: post_raw(event))

      if topic.first_post.event
        org_params = { original_starts_at: event.start_time }
        org_params[:original_ends_at] = event.end_time if add_end_time(event)
        org_params[:url] = event.url if event.url
        topic.first_post.event.update_columns(org_params)

        params = { starts_at: event.start_time }
        params[:ends_at] = event.end_time if add_end_time(event)
        topic.first_post.event.event_dates.first.update_columns(params)
      end
      topic.first_post.trigger_post_process(bypass_bump: true, priority: :low)

      topic
    end

    def post_raw(event)
      raw_params = "start=\"#{event.start_time}\""
      raw_params += " end=\"#{event.end_time}\"" if add_end_time(event)
      raw_params += " url=\"#{event.url}\"" if event.url

      raw = "[event #{raw_params}]\n[/event]"
      raw += "\n#{event.description}" if event.description.present?
      raw
    end

    def add_end_time(event)
      event.end_time && event.end_time > event.start_time
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
