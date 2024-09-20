# frozen_string_literal: true

module DiscourseEvents
  class Publisher::DiscourseCalendar < Publisher
    def ready?
      defined?(DiscoursePostEvent) == "constant" && DiscoursePostEvent.class == Module &&
        ::SiteSetting.calendar_enabled && ::SiteSetting.discourse_post_event_enabled
    end

    def get_event_data(post)
      return nil unless post&.event&.starts_at.present?
      event = post.event

      Publisher::EventData.new(
        start_time: event.starts_at,
        end_time: event.ends_at,
        name: event.name,
        url: event.url,
      )
    end
  end
end
