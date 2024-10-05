# frozen_string_literal: true

module DiscourseEvents
  class Publisher::DiscourseEvents < Publisher
    def ready?
      true
    end

    def get_client_event(post)
      post.topic.event
    end

    def get_event(post)
      event = get_client_event(post)
      return nil unless event.present?

      Publisher::Event.new(
        start_time: event[:start],
        end_time: event[:end],
        name: post.topic.title,
        description: post.topic.excerpt,
        url: event[:url],
      )
    end

    def get_registrations(post)
      event = get_client_event(post)
      return [] unless event.present? && event[:going].present?

      User
        .where(username: event[:going])
        .joins(:user_emails)
        .where("user_emails.primary")
        .pluck("users.id, user_emails.email as email, users.name")
        .map do |user_going|
          Publisher::Registration.new(
            user_id: user_going[0],
            email: user_going[1],
            name: user_going[2],
            status: "confirmed",
          )
        end
    end
  end
end
