# frozen_string_literal: true

module DiscourseEvents
  class Publisher::DiscourseCalendar < Publisher
    def ready?
      ::DiscourseEvents.discourse_post_event_ready?
    end

    def get_client_event(post)
      post.event
    end

    def get_event(post)
      event = get_client_event(post)
      return nil if event.blank?

      Publisher::Event.new(
        start_time: event.starts_at,
        end_time: event.ends_at,
        name: event.name,
        url: event.url,
      )
    end

    def get_registrations(post)
      event = get_client_event(post)
      return [] if event.invitees.blank?

      event.invitees.map do |invitee|
        Publisher::Registration.new(
          user_id: invitee.user.id,
          email: invitee.user.email,
          name: invitee.user.name,
          status:
            Syncer::DiscourseCalendar::STATUS_MAP.key(
              DiscoursePostEvent::Invitee.statuses[invitee.status].to_s,
            ),
        )
      end
    end
  end
end
