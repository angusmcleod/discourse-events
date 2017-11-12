class CalendarEvents::List
  def self.category(opts)
    topics = Topic.joins("INNER JOIN topic_custom_fields
                          ON topic_custom_fields.topic_id = topics.id
                          AND (topic_custom_fields.name = 'event_start'
                              OR topic_custom_fields.name = 'event_end')")
    topics = topics.where(category_id: opts[:category_id])
    events = []

    topics.each do |t|
      event_start = t.custom_fields['event_start']
      event_end = t.custom_fields['event_end']

      within_period = case opts[:period]
                      when 'upcoming'
                        event_start >= Time.now.iso8601
                      when 'past'
                        event_end < Time.now.iso8601
                      else
                        true
      end

      events.push(t) if within_period

      events
    end
  end

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
