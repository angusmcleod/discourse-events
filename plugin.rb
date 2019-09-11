# name: discourse-events
# about: Allows you to manage events in Discourse
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-events

register_asset 'stylesheets/common/events.scss'
register_asset 'stylesheets/desktop/events.scss', :desktop
register_asset 'stylesheets/mobile/events.scss', :mobile
register_asset 'lib/jquery.timepicker.min.js'
register_asset 'lib/jquery.timepicker.scss'
register_asset 'lib/moment-timezone-with-data-2012-2022.js'

gem 'icalendar', '2.4.1'

Discourse.top_menu_items.push(:agenda)
Discourse.anonymous_top_menu_items.push(:agenda)
Discourse.filters.push(:agenda)
Discourse.anonymous_filters.push(:agenda)
Discourse.top_menu_items.push(:calendar)
Discourse.anonymous_top_menu_items.push(:calendar)
Discourse.filters.push(:calendar)
Discourse.anonymous_filters.push(:calendar)

register_svg_icon "rss" if respond_to?(:register_svg_icon)

load File.expand_path('../models/events_timezone_default_site_setting.rb', __FILE__)
load File.expand_path('../models/events_timezone_display_site_setting.rb', __FILE__)

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
  add_to_serializer(:site, :event_timezones) { EventsTimezoneDefaultSiteSetting.values }

  Category.register_custom_field_type('events_enabled', :boolean)
  Category.register_custom_field_type('events_agenda_enabled', :boolean)
  Category.register_custom_field_type('events_calendar_enabled', :boolean)
  Category.register_custom_field_type('events_min_trust_to_create', :integer)
  Category.register_custom_field_type('events_required', :boolean)
  Category.register_custom_field_type('events_event_label_no_text', :boolean)

  [
    "events_enabled",
    "events_event_label_no_text",
    "events_agenda_enabled",
    "events_calendar_enabled",
    "events_min_trust_to_create",
    "events_required"
  ].each do |key|
    Site.preloaded_category_custom_fields << key if Site.respond_to? :preloaded_category_custom_fields
    add_to_serializer(:basic_category, key.to_sym) { object.send(key) }
  end

  class ::Category
    def events_min_trust_to_create
      if self.custom_fields['events_min_trust_to_create'].present?
        self.custom_fields['events_min_trust_to_create'].to_i
      else
        SiteSetting.events_min_trust_to_create
      end
    end

    def events_enabled
      if self.custom_fields['events_enabled'] != nil
        self.custom_fields['events_enabled']
      else
        SiteSetting.events_enabled
      end
    end

    def events_agenda_enabled
      if self.custom_fields['events_agenda_enabled'] != nil
        self.custom_fields['events_agenda_enabled']
      else
        SiteSetting.events_agenda_enabled
      end
    end

    def events_calendar_enabled
      if self.custom_fields['events_calendar_enabled'] != nil
        self.custom_fields['events_calendar_enabled']
      else
        SiteSetting.events_calendar_enabled
      end
    end

    def events_required
      if self.custom_fields['events_required'] != nil
        self.custom_fields['events_required']
      else
        false
      end
    end

    def events_event_label_no_text
      if self.custom_fields['events_event_label_no_text'] != nil
        self.custom_fields['events_event_label_no_text']
      else
        false
      end
    end
  end

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
  Topic.register_custom_field_type('event_rsvp', :boolean)
  Topic.register_custom_field_type('event_going_max', :integer)

  TopicList.preloaded_custom_fields << 'event_start' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_end' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_all_day' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_timezone' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_rsvp' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_going' if TopicList.respond_to? :preloaded_custom_fields
  TopicList.preloaded_custom_fields << 'event_going_max' if TopicList.respond_to? :preloaded_custom_fields

  load File.expand_path('../lib/calendar_events.rb', __FILE__)
  load File.expand_path('../controllers/event_rsvp.rb', __FILE__)
  load File.expand_path('../controllers/api_keys.rb', __FILE__)

  # a combined hash with iso8601 dates is easier to work with
  require_dependency 'topic'
  class ::Topic
    def has_event?
      self.custom_fields['event_start'].present? &&
      self.custom_fields['event_start'].is_a?(Numeric) &&
      self.custom_fields['event_start'] != 0
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

      if event_rsvp
        event[:rsvp] = event_rsvp

        if event_going_max
          event[:going_max] = event_going_max
        end

        if event_going
          event[:going] = event_going
        end
      end

      event
    end

    def event_going
      if self.custom_fields['event_going']
        self.custom_fields['event_going'].split(',')
      else
        []
      end
    end

    def event_rsvp
      if self.custom_fields['event_rsvp'] != nil
        self.custom_fields['event_rsvp']
      else
        false
      end
    end

    def event_going_max
      if self.custom_fields['event_going_max'].to_i > 0
        self.custom_fields['event_going_max'].to_i
      else
        nil
      end
    end
  end

  require_dependency 'topic_view_serializer'
  class ::TopicViewSerializer
    attributes :event, :event_going

    def event
      object.topic.event
    end

    def include_event?
      object.topic.has_event?
    end

    def event_going
      object.topic.event_going
    end

    def include_event_going?
      include_event?
    end
  end

  require_dependency 'topic_list_item_serializer'
  class ::TopicListItemSerializer
    attributes :event, :event_going_total

    def event
      object.event
    end

    def include_event?
      object.has_event?
    end

    def event_going_total
      object.event_going.length
    end

    def include_event_going_total?
      include_event?
    end
  end

  User.register_custom_field_type('calendar_first_day_week', :integer)
  add_to_serializer(:current_user, :calendar_first_day_week) { object.custom_fields['calendar_first_day_week'] }
  register_editable_user_custom_field :calendar_first_day_week if defined? register_editable_user_custom_field

  UserApiKey::SCOPES.reverse_merge!(
    CalendarEvents::USER_API_KEY_SCOPE.to_sym => [
      [:get, 'list#calendar_ics'],
      [:get, 'list#agenda_ics'],
      [:get, 'list#calendar_feed'],
      [:get, 'list#agenda_feed'],
    ],
  )

  PostRevisor.track_topic_field(:event)

  PostRevisor.class_eval do
    track_topic_field(:event) do |tc, event|
      if tc.guardian.can_edit_event?(tc.topic.category)
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

        rsvp = event['rsvp'] ? event['rsvp'] === 'true' : false
        tc.record_change('event_rsvp', tc.topic.custom_fields['event_rsvp'], rsvp)
        tc.topic.custom_fields['event_rsvp'] = rsvp

        if rsvp
          going_max = event['going_max'] ? event['going_max'].to_i : nil
          tc.record_change('event_going_max', tc.topic.custom_fields['event_going_max'], going_max)
          tc.topic.custom_fields['event_going_max'] = going_max

          going = event['going'] ? event['going'].join(',') : ''
          tc.record_change('event_going', tc.topic.custom_fields['event_going'], going)
          tc.topic.custom_fields['event_going'] = going
        end
      end
    end
  end

  DiscourseEvent.on(:post_created) do |post, opts, user|
    if post.is_first_post? && opts[:event]
      topic = Topic.find(post.topic_id)

      guardian = Guardian.new(user)
      guardian.ensure_can_create_event!(topic.category)

      event = opts[:event].is_a?(String) ? ::JSON.parse(opts[:event]) : opts[:event]
      event_start = event['start']
      event_end = event['end']
      event_all_day = event['all_day']
      timezone = event['timezone']
      rsvp = event['rsvp']
      going_max = event['going_max']
      going = event['going']

      topic.custom_fields['event_start'] = event_start.to_datetime.to_i if event_start
      topic.custom_fields['event_end'] = event_end.to_datetime.to_i if event_end
      topic.custom_fields['event_all_day'] = event_all_day === 'true' if event_all_day
      topic.custom_fields['event_timezone'] = timezone if timezone
      topic.custom_fields['event_rsvp'] = rsvp if rsvp
      topic.custom_fields['event_going_max'] = going_max if going_max
      topic.custom_fields['event_going'] = going if going

      topic.save_custom_fields(true)
    end
  end

  TopicQuery.add_custom_filter(:start) do |topics, query|
    if query.options[:calendar] && query.options[:start]
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
    if query.options[:calendar] && query.options[:end]
      topics.where("topics.id in (
        SELECT topic_id FROM topic_custom_fields
        WHERE (name = 'event_start' OR name = 'event_end')
        AND value <= '#{query.options[:end].to_datetime.end_of_day.to_i}'
      )")
    else
      topics
    end
  end

  module EventsGuardian
    def can_create_event?(category)
      category.events_enabled &&
      can_create_topic_on_category?(category) &&
      (is_staff? ||
      (user && user.trust_level >= category.events_min_trust_to_create))
    end

    def can_edit_event?(category)
      can_create_event?(category)
    end
  end

  require_dependency 'guardian'
  class ::Guardian
    include EventsGuardian
  end

  require_dependency 'topic'
  class ::Topic
    attr_accessor :include_excerpt
  end

  module ListableTopicSerializerExtension
    def include_excerpt?
      super || object.include_excerpt
    end
  end

  require_dependency 'listable_topic_serializer'
  class ::ListableTopicSerializer
    prepend ListableTopicSerializerExtension
  end

  require_dependency 'topic_query'
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
      topics = default_results(options.reverse_merge(ascending: 'true'))
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

      topics = topics.order("(
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
        ) ASC")

      if options[:include_excerpt]
        topics.each { |t| t.include_excerpt = true }
      end

      topics
    end
  end

  require 'icalendar/tzinfo'

  ListController.class_eval do
    skip_before_action :ensure_logged_in, only: [:calendar_ics, :agenda_ics]

    USER_API_KEY ||= "user_api_key"
    USER_API_CLIENT_ID ||= "user_api_client_id"

    def calendar_feed
      set_category if params[:category]
      self.send('event_feed', name: 'calendar', start: params[:start], end: params[:end])
    end

    def agenda_feed
      set_category if params[:category]
      self.send('event_feed', name: 'agenda')
    end

    def calendar_ics
      set_category if params[:category]
      self.send('event_ics', name: 'calendar')
    end

    def agenda_ics
      set_category if params[:category]
      self.send('event_ics', name: 'agenda')
    end

    def event_feed(opts = {})
      discourse_expires_in 1.minute

      guardian.ensure_can_see!(@category) if @category

      title_prefix = @category ? "#{SiteSetting.title} - #{@category.name}" : SiteSetting.title
      base_url = @category ? @category.url : Discourse.base_url
      list_opts = {}
      list_opts[:category] = @category.id if @category

      @title = "#{title_prefix} #{I18n.t("rss_description.events")}"
      @link = "#{base_url}/#{opts[:name]}"
      @atom_link = "#{base_url}/#{opts[:name]}.rss"
      @description = I18n.t("rss_description.events")
      @topic_list = TopicQuery.new(nil, list_opts).list_agenda

      render 'list', formats: [:rss]
    end

    def event_ics(opts = {})
      guardian.ensure_can_see!(@category) if @category

      name_prefix = @category ? "#{SiteSetting.title} - #{@category.name}" : SiteSetting.title
      base_url = @category ? @category.url : Discourse.base_url

      calendar_name = "#{name_prefix} #{I18n.t("webcal_description.events")}"
      calendar_url = "#{base_url}/calendar"
      list_opts = {}
      list_opts[:category] = @category.id if @category
      list_opts[:tags] = params[:tags] if params[:tags]
      
      if current_user &&
         SiteSetting.respond_to?(:assign_enabled) &&
         SiteSetting.assign_enabled
        list_opts[:assigned] = current_user.username if params[:assigned]
      end 

      tzid = params[:time_zone]
      tz = TZInfo::Timezone.get tzid

      cal = Icalendar::Calendar.new
      cal.x_wr_calname = calendar_name
      cal.x_wr_timezone = tzid
      # add timezone once per calendar
      event_now = DateTime.now
      timezone = tz.ical_timezone event_now
      cal.add_timezone timezone

      @topic_list = TopicQuery.new(current_user, list_opts).list_calendar

      @topic_list.topics.each do |t|
        if t.event && t.event[:start]
          event = CalendarEvents::Helper.localize_event(t.event, tzid)
          timezone = tz.ical_timezone event[:start]

          ## to do: check if working later
          if event[:format] == :date_only
            event[:start] = event[:start].to_date
            event[:end] = event[:end].to_date if event[:end]
          end

          cal.event do |e|
            e.dtstart = Icalendar::Values::DateTime.new event[:start], 'tzid' => tzid
            if event[:end]
              e.dtend = Icalendar::Values::DateTime.new event[:end], 'tzid' => tzid
            end
            e.summary = t.title
            e.description = t.url << "\n\n" << t.excerpt #add url to event body
            e.url = t.url #most calendar clients don't display this field
          end
        end
      end

      cal.publish

      render body: cal.to_ical, formats: [:ics], content_type: Mime::Type.lookup("text/calendar") unless performed?
    end

    # Logging in with user API keys normally only works by passing certain headers.
    # As we cannot force third-party software to send those headers, we need to fake
    # them using request parameters.
    def current_user
      if params.key?(USER_API_KEY)
        request.env[Auth::DefaultCurrentUserProvider::USER_API_KEY] = params[USER_API_KEY]
        if params.key?(USER_API_CLIENT_ID)
          request.env[Auth::DefaultCurrentUserProvider::USER_API_CLIENT_ID] = params[USER_API_CLIENT_ID]
        end
      end
      super
    end
  end

  on(:approved_post) do |reviewable, post|
    event = reviewable.payload['event']
    if (
    event.present? &&
      event['event_start'].present? &&
      event['event_start'].is_a?(Numeric) &&
      event['event_start'] != 0
    )

      topic = post.topic
      event.each do |k,v|
        topic.custom_fields[k] = v
      end

      topic.save_custom_fields(true)
    end
  end

  NewPostManager.add_handler(1) do |manager|
    if manager.args['event'] && NewPostManager.post_needs_approval?(manager) && NewPostManager.is_first_post?(manager)
      NewPostManager.add_plugin_payload_attribute('event') if NewPostManager.respond_to?(:add_plugin_payload_attribute)
    end

    nil
  end

  Discourse::Application.routes.prepend do
    get "calendar.ics" => "list#calendar_ics", format: :ics, protocol: :webcal
    get "agenda.ics" => "list#agenda_ics", format: :ics, protocol: :webcal
    get "c/:category/l/calendar.ics" => "list#calendar_ics", format: :ics, protocol: :webcal
    get "c/:parent_category/:category/l/calendar.ics" => "list#calendar_ics", format: :ics, protocol: :webcal
    get "c/:category/l/agenda.ics" => "list#agenda_ics", format: :ics, protocol: :webcal
    get "c/:parent_category/:category/l/agenda.ics" => "list#agenda_ics", format: :ics, protocol: :webcal

    get "c/:category/l/calendar.rss" => "list#calendar_feed", format: :rss
    get "c/:parent_category/:category/l/calendar.rss" => "list#calendar_feed", format: :rss
    get "c/:category/l/agenda.rss" => "list#agenda_feed", format: :rss
    get "c/:parent_category/:category/l/agenda.rss" => "list#agenda_feed", format: :rss

    mount ::CalendarEvents::Engine, at: '/calendar-events'
  end
end
