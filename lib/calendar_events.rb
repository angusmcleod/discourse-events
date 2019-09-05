module ::CalendarEvents
  class Engine < ::Rails::Engine
    engine_name 'calendar_events'
    isolate_namespace CalendarEvents
  end

  USER_API_KEY_SCOPE = 'calendar_events'
end

CalendarEvents::Engine.routes.draw do
  post '/rsvp/add' => 'rsvp#add'
  post '/rsvp/remove' => 'rsvp#remove'
  get '/api_keys' => 'api_keys#index'
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
    event_end = event[:end].present? ? event[:end].to_datetime : nil
    format = event[:all_day] ? :date_only : :long

    event_timezone = SiteSetting.events_timezone_default
    event_timezone = event[:timezone] if event[:timezone].present?
    event_timezone = timezone if timezone.present?

    if event_timezone.present?
      event_start = event_start.in_time_zone(event_timezone)

      if event_end
        event_end = event_end.in_time_zone(event_timezone)
      end
    end

    result = {
      start: event_start,
      end: event_end,
      format: format
    }

    if event_timezone.present?
      result[:timezone] = event_timezone
      result[:offset] = timezone_offset(event_timezone)
    end

    result
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
