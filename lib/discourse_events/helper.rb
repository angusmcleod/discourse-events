# frozen_string_literal: true

module DiscourseEvents
  class Helper
    def self.localize_event(event, timezone = nil)
      event_start = event[:start].to_datetime
      event_end = event[:end].present? ? event[:end].to_datetime : nil
      format = event[:all_day] ? :date_only : :long
      event_version  = event[:version] if event[:version]

      event_timezone = SiteSetting.events_timezone_default
      event_timezone = event[:timezone] if event[:timezone].present?
      event_timezone = timezone if timezone.present?

      if event[:rsvp]
        event_going = event[:going]
      end

      if event_timezone.present?
        event_start = event_start.in_time_zone(event_timezone)

        if event_end
          event_end = event_end.in_time_zone(event_timezone)
        end
      end

      result = {
        start: event_start,
        end: event_end,
        format: format,
        version: event_version
      }

      if event_timezone.present?
        result[:timezone] = event_timezone
        result[:offset] = timezone_offset(event_timezone)
      end

      if event_going.present?
        result[:going] = event_going
      end

      result
    end

    def self.timezone_offset(timezone)
      Time.now.in_time_zone(timezone).utc_offset / 1.hour
    end

    def self.timezone_label(event)
      return '' if !event[:timezone]

      standard_tz = DiscourseEventsTimezoneDefaultSiteSetting.values.select do |tz|
        tz[:value] === event[:timezone]
      end

      if standard_tz.first
        label = standard_tz.first[:name]
      else
        event_offset = event[:offset].present? ? event[:offset].to_i : 0
        offset_prefix = "GMT"
        offset = event_offset < 0 ? event_offset : "+ #{event_offset}"
        label = " (#{offset_prefix}#{offset}) #{event[:timezone]}"
      end

      label
    end
  end
end
