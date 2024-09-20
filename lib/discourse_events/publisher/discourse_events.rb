# frozen_string_literal: true

module DiscourseEvents
  class Publisher::DiscourseEvents < Publisher
    def ready?
      true
    end

    def get_event_data(post)
      return nil unless post.topic.event.present?
      event = post.topic.event

      Publisher::EventData.new(
        start_time: event[:start],
        end_time: event[:end],
        name: post.topic.title,
        description: post.topic.excerpt,
        url: event[:url],
      )
    end
  end
end
