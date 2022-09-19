# frozen_string_literal: true
# name: discourse-events
# about: Allows you to manage events in Discourse
# version: 0.1.1
# authors: Angus McLeod
# contact_emails: development@pavilion.tech
# url: https://github.com/paviliondev/discourse-events

register_asset 'stylesheets/common/events.scss'
register_asset 'stylesheets/desktop/events.scss', :desktop
register_asset 'stylesheets/mobile/events.scss', :mobile
register_asset 'lib/jquery.timepicker.min.js'
register_asset 'lib/jquery.timepicker.scss'
register_asset 'lib/moment-timezone-with-data-2012-2022.js'

gem 'ice_cube', '0.16.4'
gem 'icalendar', '2.8.0'

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

after_initialize do
  [
    "../lib/calendar_events.rb",
    "../lib/event_creator.rb",
    "../lib/event_revisor.rb",
    "../lib/topic_query_edits.rb",
    "../controllers/event_rsvp.rb",
    "../controllers/api_keys.rb",
    "../controllers/list_controller_edits.rb"
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

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
    add_to_class(:category, key.to_sym) do
      self.custom_fields[key] || (SiteSetting.respond_to?(key) ? SiteSetting.send(key) : false)
    end
    add_to_serializer(:basic_category, key.to_sym) { object.send(key) }
  end

  module EventsSiteSettingExtension
    def type_hash(name)
      add_choices(name) if name == :top_menu
      super
    end

    def validate_value(name, type, val)
      add_choices(name) if name == :top_menu
      super
    end

    def add_choices(name)
      @choices[name].push("agenda") if @choices[name].exclude?("agenda")
      @choices[name].push("calendar") if @choices[name].exclude?("calendar")
    end
  end

  ::SiteSettings::TypeSupervisor.prepend EventsSiteSettingExtension

  # event times are stored individually as seconds since epoch so that event topic lists
  # can be ordered easily within the exist topic list query structure in Discourse core.
  Topic.register_custom_field_type('event_start', :integer)
  Topic.register_custom_field_type('event_end', :integer)
  Topic.register_custom_field_type('event_all_day', :boolean)
  Topic.register_custom_field_type('event_rsvp', :boolean)
  Topic.register_custom_field_type('event_going', :json)
  Topic.register_custom_field_type('event_going_max', :integer)
  Topic.register_custom_field_type('event_version', :integer)

  if TopicList.respond_to? :preloaded_custom_fields
    preloaded_custom_fields = [
      'event_start',
      'event_end',
      'event_all_day',
      'event_timezone',
      'event_rsvp',
      'event_going',
      'event_going_max',
      'event_version',
    ]
    TopicList.preloaded_custom_fields += preloaded_custom_fields
  end

  # a combined hash with iso8601 dates is easier to work with
  add_to_class(:topic, :has_event?) do
    self.custom_fields['event_start'].present? &&
    self.custom_fields['event_start'].is_a?(Numeric) &&
    self.custom_fields['event_start'] != 0
  end

  [
    "event_going",
    "event_rsvp",
    "event_going_max",
  ].each do |key|
    add_to_class(:topic, key.to_sym) do
      self.custom_fields[key] || false
    end
  end

  add_to_class(:topic, :event) do
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

    if custom_fields['event_version'].present?
      event[:version] = custom_fields['event_version']
    end

    if event_rsvp
      event[:rsvp] = event_rsvp

      if event_going_max
        event[:going_max] = event_going_max
      end

      if event_going
        event[:going] = User.find(event_going).pluck(:username)
      end
    end

    event
  end

  add_to_serializer(:topic_view, :event, false) do
    object.topic.event
  end

  add_to_serializer(:topic_view, :include_event?, false) do
    object.topic.has_event?
  end

  add_to_serializer(:topic_list_item, :event, false) do
    object.event
  end

  add_to_serializer(:topic_list_item, :include_event?, false) do
    object.has_event?
  end

  add_to_serializer(:topic_list_item, :event_going_total) do
    object.event_going ? object.event_going.length : 0
  end

  add_to_serializer(:topic_list_item, :include_event_going_total?) do
    include_event?
  end

  User.register_custom_field_type('calendar_first_day_week', :integer)
  add_to_serializer(:current_user, :calendar_first_day_week) { object.custom_fields['calendar_first_day_week'] }
  register_editable_user_custom_field :calendar_first_day_week if defined? register_editable_user_custom_field

  add_user_api_key_scope(CalendarEvents::USER_API_KEY_SCOPE.to_sym,
    methods: :get,
    actions: ['list#calendar_ics',
              'list#agenda_ics',
              'list#calendar_feed',
              'list#agenda_feed'],
    formats: [:ics, :rss],
    params: [:tags, :assigned, :time_zone, ListControllerEventsExtension::USER_API_KEY.to_sym, ListControllerEventsExtension::USER_API_CLIENT_ID.to_sym ]
  )

  add_to_class(:guardian, :can_create_event?) do |category|
    category.events_enabled &&
    can_create_topic_on_category?(category) &&
    (is_staff? ||
    (user && user.trust_level >= category.events_min_trust_to_create))
  end

  add_to_class(:guardian, :can_edit_event?) do |category|
    can_create_event?(category)
  end

  class ::Topic
    attr_accessor :include_excerpt
  end

  module ListableTopicSerializerExtension
    def include_excerpt?
      super || object.include_excerpt
    end
  end

  ::ListableTopicSerializer.prepend ListableTopicSerializerExtension

  on(:post_created) do |post, opts, user|
    event_creator = ::EventCreator.new(post, opts, user)
    event_creator.create
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
      event.each do |k, v|
        topic.custom_fields[k] = v
      end

      topic.save_custom_fields(true)
    end
  end

  ::PostRevisor.track_topic_field(:event) do |tc, event|
    event_revisor = EventRevisor.new(tc, event)
    event_revisor.revise!
  end

  ::NewPostManager.add_handler(1) do |manager|
    if manager.args['event'] && NewPostManager.post_needs_approval?(manager) && NewPostManager.is_first_post?(manager)
      NewPostManager.add_plugin_payload_attribute('event') if NewPostManager.respond_to?(:add_plugin_payload_attribute)
    end

    nil
  end

  Discourse::Application.routes.prepend do
    get "calendar.ics" => "list#calendar_ics", format: :ics, protocol: :webcal
    get "calendar.rss" => "list#calendar_feed", format: :rss
    get "agenda.rss" => "list#agenda_feed", format: :rss

    %w{users u}.each do |root_path|
      get "#{root_path}/:username/preferences/webcal-keys" => "users#preferences", constraints: { username: RouteFormat.username }
    end

    get "c/*category_slug_path_with_id/l/calendar.ics" => "list#calendar_ics", format: :ics, protocol: :webcal
    get "c/*category_slug_path_with_id/l/calendar.rss" => "list#calendar_feed", format: :rss
    get "c/*category_slug_path_with_id/l/agenda.rss" => "list#agenda_feed", format: :rss

    mount ::CalendarEvents::Engine, at: '/calendar-events'
  end
end

on(:locations_ready) do
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

on(:custom_wizard_ready) do
  if defined?(CustomWizard) == 'constant' && CustomWizard.class == Module
    action_callback = proc { |params, wizard, action, submission|
      if action['add_event']
        event = CustomWizard::Mapper.new(
          inputs: action['add_event'],
          data: submission&.fields_and_meta,
          user: wizard.user
        ).perform

        if event['start'].present?
          event_params = {
            'event_start': event['start'].to_datetime.to_i
          }

          event_params['event_end'] = event['end'].to_datetime.to_i if event['end'].present?
          event_params['event_all_day'] = event['all_day'] === 'true' if event['all_day'].present?
          event_params['event_timezone'] = event['timezone'] if event['timezone'].present?
          event_params['event_rsvp'] = event['rsvp'] if event['rsvp'].present?
          event_params['event_going_max'] = event['going_max'] if event['going_max'].present?
          event_params['event_going'] = User.where(username: event['going']).pluck(:id) if event['going'].present?
          event_params['event_version'] = 1

          params[:topic_opts] ||= {}
          params[:topic_opts][:custom_fields] ||= {}
          params[:topic_opts][:custom_fields].merge!(event_params)
        end
      end

      params
    }
    CustomWizard::Field.register('event', 'discourse-events', action_callback: action_callback)
  end
end

on(:user_destroyed) do |user|
  user_id = user.id
  topic_ids = TopicCustomField.where(name: 'event_going').pluck(:topic_id)
  topics = Topic.where(id: topic_ids) if topic_ids.present?

  if topics
    topics.each do |topic|
      rsvp_array = topic.custom_fields['event_going'] || []
      rsvp_array.delete(user.id)
      topic.custom_fields['event_going'] = rsvp_array
      topic.save_custom_fields(true)
    end
  end
end
