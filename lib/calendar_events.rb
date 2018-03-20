module ::CalendarEvents
  class Engine < ::Rails::Engine
    engine_name 'calendar_events'
    isolate_namespace CalendarEvents
  end
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
  def self.localize_event(event, tz = nil)
    event_start_utc = event[:start].to_datetime
    event_end_utc = event[:end].present? ? event[:end].to_datetime : event_start_utc

    time_zone = tz ? tz : event[:event_timezone]
    event_start = event_start_utc.in_time_zone(time_zone)
    event_end = event_end_utc.in_time_zone(time_zone)

    { start: event_start, end: event_end }
  end
end
