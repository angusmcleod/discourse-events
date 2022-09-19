# frozen_string_literal: true
::TopicQuery.add_custom_filter(:start) do |topics, query|
  if query.options[:start]
    topics.where("topics.id in (
      SELECT topic_id FROM topic_custom_fields
      WHERE (name = 'event_start' OR name = 'event_end')
      AND value >= '#{query.options[:start].to_datetime.beginning_of_day.to_i}'
    )")
  else
    topics
  end
end

::TopicQuery.add_custom_filter(:end) do |topics, query|
  if query.options[:end]
    topics.where("topics.id in (
      SELECT topic_id FROM topic_custom_fields
      WHERE (name = 'event_start' OR name = 'event_end')
      AND value <= '#{query.options[:end].to_datetime.end_of_day.to_i}'
    )")
  else
    topics
  end
end

class ::TopicQuery
  def list_agenda
    @options[:unordered] = true
    @options[:list] = 'agenda'

    opts = {
      remove_past: SiteSetting.events_remove_past_from_agenda
    }

    opts[:status] = 'open' if SiteSetting.events_agenda_filter_closed

    create_list(:agenda, {}, event_results(opts))
  end

  def list_calendar
    @options[:unordered] = true
    @options[:list] = 'calendar'

    opts = {
      limit: false,
      include_excerpt: true,
      remove_past: SiteSetting.events_remove_past_from_calendar
    }

    opts[:status] = 'open' if SiteSetting.events_calendar_filter_closed

    create_list(:calendar, {}, event_results(opts))
  end

  def event_results(options = {})
    topics = default_results(options)
      .joins("INNER JOIN topic_custom_fields
              ON topic_custom_fields.topic_id = topics.id
              AND topic_custom_fields.name = 'event_start'
              AND topic_custom_fields.value <> ''")

    CalendarEvents::List.sorted_filters.each do |filter|
      topics = filter[:block].call(topics, @options)
    end

    if options[:remove_past]
      topics = topics.where("topics.id in (
        SELECT topic_id FROM topic_custom_fields
        WHERE (name = 'event_start' OR name ='event_end')
        AND value > '#{Time.now.to_i}'
      )")
    end

    topics = topics.reorder("(
        SELECT CASE
        WHEN EXISTS (
          SELECT true FROM topic_custom_fields tcf
          WHERE tcf.topic_id::integer = topics.id::integer
          AND tcf.name = 'event_start' LIMIT 1
        )
        THEN (
          SELECT value::integer FROM topic_custom_fields tcf
          WHERE tcf.topic_id::integer = topics.id::integer
          AND tcf.name = 'event_start' LIMIT 1
        )
        ELSE 0 END
      ) ASC") if [nil, "default"].include? @options[:order]

    if options[:include_excerpt]
      topics.each { |t| t.include_excerpt = true }
    end

    topics
  end
end
