module ::CalendarEvents
  class Engine < ::Rails::Engine
    engine_name 'calendar_events'
    isolate_namespace CalendarEvents
  end
end

CalendarEvents::Engine.routes.draw do
  post '/rsvp/add' => 'rsvp#add'
  post '/rsvp/remove' => 'rsvp#remove'
end

class CalendarEvents::List
  def self.sorted_filters
    @sorted_filters ||= []
  end

  def self.filters
    sorted_filters.map { |h| { block: h[:block] } }
  end

  def self.add_filter(priority = 0, &block)
    sorted_filters << { priority: priority, block: block }
    @sorted_filters.sort_by! { |h| -h[:priority] }
  end
end

class CalendarEvents::Helper
  def self.localize_event(event, timezone = nil)
    event_start = event[:start].to_datetime
    event_end = event[:end].present? ? event[:end].to_datetime : event_start

    event_timezone = SiteSetting.events_timezone_default
    event_timezone = event[:timezone] if event[:timezone].present?
    event_timezone = timezone if timezone.present?

    localized_event_start = event_start.in_time_zone(event_timezone)
    localized_event_end = event_end.in_time_zone(event_timezone)

    {
      start: localized_event_start,
      end: localized_event_end,
      timezone: event_timezone,
      offset: timezone_offset(event_timezone)
    }
  end

  def self.timezone_offset(timezone)
    Time.now.in_time_zone(timezone).utc_offset / 1.hour
  end

  def self.timezone_label(event)
    return '' if !event[:timezone]

    standard_tz = EventsTimezoneDefaultSiteSetting.values.select do |tz|
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
