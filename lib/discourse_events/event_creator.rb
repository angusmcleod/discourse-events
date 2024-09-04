# frozen_string_literal: true

module DiscourseEvents
  class EventCreator
    def initialize(post, opts, user)
      @post = post
      @opts = opts
      @user = user
    end

    def is_wizard_event?
      !!(
        @opts[:topic_opts] && @opts[:topic_opts][:custom_fields] &&
          @opts[:topic_opts][:custom_fields]["event"]
      )
    end

    def is_event?
      @opts[:event] || is_wizard_event?
    end

    def is_first_post?
      @post.is_first_post?
    end

    def create
      if is_first_post? && is_event?
        topic = Topic.find(@post.topic_id)
        event_params =
          is_wizard_event? ? @opts[:topic_opts][:custom_fields]["event"] : @opts[:event]
        guardian = Guardian.new(@user)
        guardian.ensure_can_create_event!(topic.category)

        event =
          (
            event_params.is_a?(String) ? ::JSON.parse(event_params) : event_params
          ).with_indifferent_access
        event_start = event["start"] ? event["start"].to_datetime : nil
        event_end = event["end"] ? event["end"].to_datetime : nil

        topic.custom_fields["event_start"] = event_start.to_i if event_start
        topic.custom_fields["event_end"] = event_end.to_i if event_end
        topic.custom_fields["event_all_day"] = event["all_day"] === "true" if event["all_day"]
        topic.custom_fields["event_timezone"] = event["timezone"] if event["timezone"]
        topic.custom_fields["event_rsvp"] = event["rsvp"] if event["rsvp"]
        topic.custom_fields["event_going_max"] = event["going_max"] if event["going_max"]
        topic.custom_fields["event_going"] = User.where(username: event["going"]).pluck(
          :id,
        ) if event["going"]
        topic.custom_fields["event_version"] = 1

        topic.save_custom_fields(true)
      end
    end
  end
end
