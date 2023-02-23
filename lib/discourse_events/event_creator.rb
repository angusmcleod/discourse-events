# frozen_string_literal: true

module DiscourseEvents
  class EventCreator
    def initialize(post, opts, user)
      @post = post
      @opts = opts
      @user = user
    end

    def is_wizard_event?
      !!(@opts[:topic_opts] &&
        @opts[:topic_opts][:custom_fields] &&
        @opts[:topic_opts][:custom_fields]['event'])
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
        event_params = is_wizard_event? ? @opts[:topic_opts][:custom_fields]['event'] : @opts[:event]
        guardian = Guardian.new(@user)
        guardian.ensure_can_create_event!(topic.category)

        event = (event_params.is_a?(String) ? ::JSON.parse(event_params) : event_params).with_indifferent_access
        event_start = event['start']
        event_end = event['end']
        event_all_day = event['all_day']
        timezone = event['timezone']
        rsvp = event['rsvp']
        going_max = event['going_max']
        going = event['going']
        event_version = 1

        topic.custom_fields['event_start'] = event_start.to_datetime.to_i if event_start
        topic.custom_fields['event_end'] = event_end.to_datetime.to_i if event_end
        topic.custom_fields['event_all_day'] = event_all_day === 'true' if event_all_day
        topic.custom_fields['event_timezone'] = timezone if timezone
        topic.custom_fields['event_rsvp'] = rsvp if rsvp
        topic.custom_fields['event_going_max'] = going_max if going_max
        topic.custom_fields['event_going'] = User.where(username: going).pluck(:id) if going
        topic.custom_fields['event_version'] = event_version if event_version

        topic.save_custom_fields(true)
      end
    end
  end
end
