# frozen_string_literal: true

module DiscourseEvents
  class EventRevisor
    def initialize(tc, event)
      @tc = tc
      @event = event
    end

    def revise!
      @event ||= {}

      if @tc.guardian.can_edit_event?(@tc.topic.category)
        event_start = @event['start'] ? @event['start'].to_datetime.to_i : nil
        start_change = @tc.record_change('event_start', @tc.topic.custom_fields['event_start'], event_start)
        @tc.topic.custom_fields['event_start'] = event_start if start_change

        event_end = @event['end'] ? @event['end'].to_datetime.to_i : nil
        end_change = @tc.record_change('event_end', @tc.topic.custom_fields['event_end'], event_end)
        @tc.topic.custom_fields['event_end'] = event_end  if end_change

        all_day = !!@event['all_day']
        all_day_change = @tc.record_change('event_all_day', @tc.topic.custom_fields['event_all_day'], all_day)
        @tc.topic.custom_fields['event_all_day'] = all_day if all_day_change

        timezone = @event['timezone']
        timezone_change = @tc.record_change('event_timezone', @tc.topic.custom_fields['event_timezone'], timezone)
        @tc.topic.custom_fields['event_timezone'] = timezone if timezone_change

        rsvp = !!@event['rsvp']
        rsvp_change = @tc.record_change('event_rsvp', @tc.topic.custom_fields['event_rsvp'], rsvp)
        @tc.topic.custom_fields['event_rsvp'] = rsvp if rsvp_change

        if rsvp
          going_max = @event['going_max'] ? @event['going_max'].to_i : nil
          going_max_change = @tc.record_change('event_going_max', @tc.topic.custom_fields['event_going_max'], going_max)
          @tc.topic.custom_fields['event_going_max'] = going_max if going_max_change

          goingNames = @event['going']
          going = User.where(username: goingNames).pluck(:id)
          going_change = @tc.record_change('event_going', @tc.topic.custom_fields['event_going'], going)
          @tc.topic.custom_fields['event_going'] = going if going_change
        end

        if start_change || end_change || timezone_change # increment by 1, even if more than one props are changed at once
          @tc.topic.custom_fields['event_version'] = @tc.topic.custom_fields['event_version'].nil? ? 1 : @tc.topic.custom_fields['event_version'] + 1
        end
      end
    end
  end
end
