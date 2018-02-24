# name: discourse-events
# about: Allows you to manage events in Discourse
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-events

register_asset 'stylesheets/common/events.scss'
register_asset 'stylesheets/mobile/events.scss', :mobile
register_asset 'lib/jquery.timepicker.min.js'
register_asset 'lib/jquery.timepicker.scss'
register_asset 'lib/moment-timezone-with-data-2012-2022.js'

Discourse.top_menu_items.push(:agenda)
Discourse.anonymous_top_menu_items.push(:agenda)
Discourse.filters.push(:agenda)
Discourse.anonymous_filters.push(:agenda)
Discourse.top_menu_items.push(:calendar)
Discourse.anonymous_top_menu_items.push(:calendar)
Discourse.filters.push(:calendar)
Discourse.anonymous_filters.push(:calendar)

DiscourseEvent.on(:locations_ready) do
  Locations::Map.add_list_filter do |topics, options|
    if SiteSetting.events_remove_past_from_map
      topics = topics.where("NOT EXISTS (SELECT * FROM topic_custom_fields
                                         WHERE topic_id = topics.id
                                         AND name = 'event_start')
                             OR topics.id in (
                                SELECT topic_id FROM topic_custom_fields
                                WHERE (name = 'event_start' OR name = 'event_end')
                                AND value > '#{Time.now.to_i}')")
    end

    topics
  end
end

after_initialize do
  Category.register_custom_field_type('events_enabled', :boolean)
  Category.register_custom_field_type('events_agenda_enabled', :boolean)
  Category.register_custom_field_type('events_calendar_enabled', :boolean)
  Category.register_custom_field_type('events_agenda_filter_closed', :boolean)
  add_to_serializer(:basic_category, :events_enabled) { object.custom_fields['events_enabled'] }
  add_to_serializer(:basic_category, :events_agenda_enabled) { object.custom_fields['events_agenda_enabled'] }
  add_to_serializer(:basic_category, :events_calendar_enabled) { object.custom_fields['events_calendar_enabled'] }
  add_to_serializer(:basic_category, :events_agenda_filter_closed) { object.custom_fields['events_agenda_filter_closed'] }

  module EventsSiteSettingExtension
    def type_hash(name)
      if name == :top_menu
        @choices[name].push("agenda") if @choices[name].exclude?("agenda")
        @choices[name].push("calendar") if @choices[name].exclude?("calendar")
      end
      super(name)
    end
  end

  require_dependency 'site_settings/type_supervisor'
  class SiteSettings::TypeSupervisor
    prepend EventsSiteSettingExtension
  end

  # event times are stored individually as seconds since epoch so that event topic lists
  # can be ordered easily within the exist topic list query structure in Discourse core.
  Topic.register_custom_field_type('event_start', :integer)
  Topic.register_custom_field_type('event_end', :integer)
  Topic.register_custom_field_type('event_all_day', :boolean)

  TopicList.preloaded_custom_fields << 'event_start' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_end' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_all_day' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_timezone' if TopicList.respond_to? :preloaded_custom_fields

  load File.expand_path('../lib/calendar_events.rb', __FILE__)

  # a combined hash with iso8601 dates is easier to work with
  require_dependency 'topic'
  class ::Topic
    def has_event?
      self.custom_fields['event_start']&.nonzero?
    end

    def event
      return nil unless has_event?
      event = { start: Time.at(custom_fields['event_start']).iso8601 }

      if custom_fields['event_end']&.nonzero?
        event[:end] = Time.at(custom_fields['event_end']).iso8601
      end

      if custom_fields['event_timezone'].present?
        event[:timezone] = custom_fields['event_timezone']
      end

      if custom_fields['event_all_day'].present?
        event[:all_day] = custom_fields['event_all_day']
      end

      event
    end
  end

  require_dependency 'topic_view_serializer'
  class ::TopicViewSerializer
    attributes :event

    def event
      object.topic.event
    end

    def include_event?
      object.topic.has_event?
    end
  end

  require_dependency 'topic_list_item_serializer'
  class ::TopicListItemSerializer
    attributes :event

    def event
      object.event
    end

    def include_event?
      object.has_event?
    end
  end

  PostRevisor.track_topic_field(:event)

  PostRevisor.class_eval do
    track_topic_field(:event) do |tc, event|
      event_start = event['start'] ? event['start'].to_datetime.to_i : nil
      tc.record_change('event_start', tc.topic.custom_fields['event_start'], event_start)
      tc.topic.custom_fields['event_start'] = event_start

      event_end = event['end'] ? event['end'].to_datetime.to_i : nil
      tc.record_change('event_end', tc.topic.custom_fields['event_end'], event_end)
      tc.topic.custom_fields['event_end'] = event_end

      all_day = event['all_day'] ? event['all_day'] === 'true' : false
      tc.record_change('event_all_day', tc.topic.custom_fields['event_all_day'], all_day)
      tc.topic.custom_fields['event_all_day'] = all_day

      timezone = event['timezone']
      tc.record_change('event_timezone', tc.topic.custom_fields['event_timezone'], timezone)
      tc.topic.custom_fields['event_timezone'] = timezone
    end
  end

  DiscourseEvent.on(:post_created) do |post, opts, _user|
    if post.is_first_post? && opts[:event]
      topic = Topic.find(post.topic_id)

      event = opts[:event].is_a?(String) ? ::JSON.parse(opts[:event]) : opts[:event]
      event_start = event['start']
      event_end = event['end']
      event_all_day = event['all_day']
      timezone = event['timezone']

      topic.custom_fields['event_start'] = event_start.to_datetime.to_i if event_start
      topic.custom_fields['event_end'] = event_end.to_datetime.to_i if event_end
      topic.custom_fields['event_all_day'] = event_all_day === 'true' if event_all_day
      topic.custom_fields['event_timezone'] = timezone if timezone
      topic.save!
    end
  end

  TopicQuery.add_custom_filter(:start) do |topics, query|
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

  TopicQuery.add_custom_filter(:end) do |topics, query|
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

  require_dependency 'topic_query'
  class ::TopicQuery
    SORTABLE_MAPPING['agenda'] = 'custom_fields.event_start'

    def list_agenda
      @options[:order] = 'agenda'
      @options[:list] = 'agenda'
      create_list(:agenda, {}, event_results) do |topics|
        if SiteSetting.events_remove_past_from_agenda
          topics = topics.where("topics.id in (
                                  SELECT topic_id FROM topic_custom_fields
                                  WHERE name = 'event_end' AND value > '#{Time.now.to_i}'
                                ) OR topic_custom_fields.value > '#{Time.now.to_i}'")
        end

        if SiteSetting.events_agenda_filter_closed ||
          (options[:category_id] &&
          CategoryCustomField.where(category_id: options[:category_id], name: 'events_agenda_filter_closed')
                             .pluck(:value))
          topics = topics.where(closed: false)
        end

        topics
      end
    end

    def list_calendar
      @options[:order] = 'agenda'
      @options[:list] = 'calendar'
      create_list(:calendar, {}, event_results(limit: false))
    end

    def event_results(options = {})
      topics = default_results(options.reverse_merge(ascending: 'true'))
        .joins("INNER JOIN topic_custom_fields
                ON topic_custom_fields.topic_id = topics.id
                AND topic_custom_fields.name = 'event_start'")

      CalendarEvents::List.sorted_filters.each do |filter|
        topics = filter[:block].call(topics, @options)
      end

      topics
    end
  end
end
