# frozen_string_literal: true

module DiscourseEvents
  class Publisher::Events < Publisher
    def ready?
      true
    end

    def get_event_data(post)
      return nil unless post.topic.event_view.present?
      event = post.topic.event_view

      Publisher::EventData.new(
        start_time: event[:start],
        end_time: event[:end],
        name: event[:name],
        description: event[:description],
        url: event[:url],
      )
    end

    def after_publish(post, event)
      post.topic.custom_fields["event_id"] = event.id
      post.topic.save_custom_fields(true)
    end
  end
end
