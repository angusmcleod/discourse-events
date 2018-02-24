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
