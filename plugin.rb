# frozen_string_literal: true
# name: discourse-events
# about: Allows you to manage events in Discourse
# version: 0.7.0
# authors: Angus McLeod
# contact_emails: angus@pavilion.tech
# url: https://github.com/paviliondev/discourse-events

enabled_site_setting :events_enabled

add_admin_route "admin.events.title", "events"

register_asset "stylesheets/common/events.scss"
register_asset "stylesheets/common/admin.scss"
register_asset "stylesheets/desktop/events.scss", :desktop
register_asset "stylesheets/mobile/events.scss", :mobile

gem "uuidtools", "2.2.0"
gem "iso-639", "0.3.5"
gem "ice_cube", "0.16.4"
gem "icalendar", "2.8.0"
gem "icalendar-recurrence", "1.1.3"
gem "date", "3.3.4"
gem "time", "0.2.0"
gem "stringio", "3.1.1"
gem "omnievent", "0.1.0.pre3", require_name: "omnievent"
gem "omnievent-icalendar", "0.1.0.pre5", require_name: "omnievent/icalendar"
gem "omnievent-api", "0.1.0.pre2", require_name: "omnievent/api"
gem "omnievent-eventbrite", "0.1.0.pre2", require_name: "omnievent/eventbrite"
gem "omnievent-eventzilla", "0.1.0.pre2", require_name: "omnievent/eventzilla"
gem "omnievent-meetup", "0.1.0.pre1", require_name: "omnievent/meetup"
gem "omnievent-outlook", "0.1.0.pre2", require_name: "omnievent/outlook"

Discourse.top_menu_items.push(:agenda)
Discourse.anonymous_top_menu_items.push(:agenda)
Discourse.filters.push(:agenda)
Discourse.anonymous_filters.push(:agenda)
Discourse.top_menu_items.push(:calendar)
Discourse.anonymous_top_menu_items.push(:calendar)
Discourse.filters.push(:calendar)
Discourse.anonymous_filters.push(:calendar)

register_svg_icon "rss"
register_svg_icon "fingerprint"
register_svg_icon "save"

require_relative "lib/discourse_events_client_site_setting.rb"
require_relative "lib/discourse_events_timezone_default_site_setting.rb"
require_relative "lib/discourse_events_timezone_display_site_setting.rb"

after_initialize do
  require_relative "lib/discourse_events/engine.rb"
  require_relative "lib/discourse_events/helper.rb"
  require_relative "lib/discourse_events/list.rb"
  require_relative "lib/discourse_events/event_creator.rb"
  require_relative "lib/discourse_events/event_revisor.rb"
  require_relative "lib/discourse_events/logger.rb"
  require_relative "lib/discourse_events/import_manager.rb"
  require_relative "lib/discourse_events/sync_manager.rb"
  require_relative "lib/discourse_events/syncer.rb"
  require_relative "lib/discourse_events/syncer/discourse_events.rb"
  require_relative "lib/discourse_events/syncer/events.rb"
  require_relative "lib/discourse_events/auth/base.rb"
  require_relative "lib/discourse_events/auth/meetup.rb"
  require_relative "lib/discourse_events/auth/outlook.rb"
  require_relative "app/models/discourse_events/filter.rb"
  require_relative "app/models/discourse_events/connection.rb"
  require_relative "app/models/discourse_events/event_connection.rb"
  require_relative "app/models/discourse_events/event.rb"
  require_relative "app/models/discourse_events/log.rb"
  require_relative "app/models/discourse_events/provider.rb"
  require_relative "app/models/discourse_events/source.rb"
  require_relative "app/controllers/concerns/discourse_events/filters.rb"
  require_relative "app/controllers/discourse_events/admin_controller.rb"
  require_relative "app/controllers/discourse_events/api_keys_controller.rb"
  require_relative "app/controllers/discourse_events/connection_controller.rb"
  require_relative "app/controllers/discourse_events/event_controller.rb"
  require_relative "app/controllers/discourse_events/rsvp_controller.rb"
  require_relative "app/controllers/discourse_events/log_controller.rb"
  require_relative "app/controllers/discourse_events/provider_controller.rb"
  require_relative "app/controllers/discourse_events/source_controller.rb"
  require_relative "app/serializers/discourse_events/basic_event_serializer.rb"
  require_relative "app/serializers/discourse_events/filter_serializer.rb"
  require_relative "app/serializers/discourse_events/connection_serializer.rb"
  require_relative "app/serializers/discourse_events/connection_user_serializer.rb"
  require_relative "app/serializers/discourse_events/source_serializer.rb"
  require_relative "app/serializers/discourse_events/event_serializer.rb"
  require_relative "app/serializers/discourse_events/log_serializer.rb"
  require_relative "app/serializers/discourse_events/post_event_serializer.rb"
  require_relative "app/serializers/discourse_events/provider_serializer.rb"
  require_relative "app/jobs/discourse_events/scheduled/update_events.rb"
  require_relative "app/jobs/discourse_events/regular/import_source.rb"
  require_relative "app/jobs/discourse_events/regular/sync_connection.rb"
  require_relative "app/jobs/discourse_events/regular/refresh_token.rb"
  require_relative "config/routes.rb"
  require_relative "extensions/list_controller.rb"
  require_relative "extensions/site_settings_type_supervisor.rb"
  require_relative "extensions/listable_topic_serializer.rb"
  require_relative "extensions/guardian.rb"

  add_to_serializer(:site, :event_timezones) { DiscourseEventsTimezoneDefaultSiteSetting.values }

  register_category_custom_field_type("events_enabled", :boolean)
  register_category_custom_field_type("events_agenda_enabled", :boolean)
  register_category_custom_field_type("events_calendar_enabled", :boolean)
  register_category_custom_field_type("events_min_trust_to_create", :integer)
  register_category_custom_field_type("events_required", :boolean)
  register_category_custom_field_type("events_event_label_no_text", :boolean)

  %w[
    events_enabled
    events_event_label_no_text
    events_agenda_enabled
    events_calendar_enabled
    events_min_trust_to_create
    events_required
  ].each do |key|
    if CategoryList.respond_to? :preloaded_category_custom_fields
      CategoryList.preloaded_category_custom_fields << key
    end
    if Site.respond_to? :preloaded_category_custom_fields
      Site.preloaded_category_custom_fields << key
    end
    add_to_class(:category, key.to_sym) { self.custom_fields[key] }
    add_to_serializer(:basic_category, key.to_sym) { object.send(key) }
  end

  SiteSettings::TypeSupervisor.prepend SiteSettingsTypeSupervisorEventsExtension

  # event times are stored individually as seconds since epoch so that event topic lists
  # can be ordered easily within the exist topic list query structure in Discourse core.
  register_topic_custom_field_type("event_start", :integer)
  register_topic_custom_field_type("event_end", :integer)
  register_topic_custom_field_type("event_all_day", :boolean)
  register_topic_custom_field_type("event_rsvp", :boolean)
  register_topic_custom_field_type("event_going", :json)
  register_topic_custom_field_type("event_going_max", :integer)
  register_topic_custom_field_type("event_version", :integer)

  if TopicList.respond_to? :preloaded_custom_fields
    preloaded_custom_fields = %w[
      event_start
      event_end
      event_all_day
      event_timezone
      event_rsvp
      event_going
      event_going_max
      event_version
    ]
    TopicList.preloaded_custom_fields += preloaded_custom_fields
  end

  # a combined hash with iso8601 dates is easier to work with
  add_to_class(:topic, :has_event?) do
    self.custom_fields["event_start"].present? &&
      self.custom_fields["event_start"].is_a?(Numeric) && self.custom_fields["event_start"] != 0
  end

  %w[event_going event_rsvp event_going_max].each do |key|
    add_to_class(:topic, key.to_sym) { self.custom_fields[key] || false }
  end

  add_to_class(:topic, :event) do
    return nil unless has_event?
    event = { start: Time.at(custom_fields["event_start"]).iso8601 }

    if custom_fields["event_end"]&.nonzero?
      event[:end] = Time.at(custom_fields["event_end"]).iso8601
    end

    event[:timezone] = custom_fields["event_timezone"] if custom_fields["event_timezone"].present?

    event[:all_day] = custom_fields["event_all_day"] if custom_fields["event_all_day"].present?

    event[:version] = custom_fields["event_version"] if custom_fields["event_version"].present?

    if event_rsvp
      event[:rsvp] = event_rsvp

      event[:going_max] = event_going_max if event_going_max

      event[:going] = User.find(event_going).pluck(:username) if event_going
    end

    event
  end

  add_to_serializer(:topic_view, :event, include_condition: -> { object.topic.has_event? }) do
    object.topic.event
  end

  add_to_serializer(:topic_list_item, :event, include_condition: -> { object.has_event? }) do
    object.event
  end

  add_to_serializer(
    :topic_list_item,
    :event_going_total,
    include_condition: -> { object.has_event? },
  ) { object.event_going ? object.event_going.length : 0 }

  register_user_custom_field_type("calendar_first_day_week", :integer)
  add_to_serializer(:current_user, :calendar_first_day_week) do
    object.custom_fields["calendar_first_day_week"]
  end
  if defined?(register_editable_user_custom_field)
    register_editable_user_custom_field :calendar_first_day_week
  end

  add_user_api_key_scope(
    DiscourseEvents::USER_API_KEY_SCOPE.to_sym,
    methods: :get,
    actions: %w[list#calendar_ics list#agenda_ics list#calendar_feed list#agenda_feed],
    formats: %i[ics rss],
    params: [
      :tags,
      :assigned,
      :time_zone,
      ListControllerEventsExtension::USER_API_KEY.to_sym,
      ListControllerEventsExtension::USER_API_CLIENT_ID.to_sym,
    ],
  )

  add_to_class(:guardian, :can_create_event?) do |category|
    category.events_enabled && can_create_topic_on_category?(category) &&
      (is_staff? || (user && user.trust_level >= category.events_min_trust_to_create.to_i))
  end

  add_to_class(:guardian, :can_edit_event?) { |category| can_create_event?(category) }

  Topic.attr_accessor :include_excerpt

  ListableTopicSerializer.prepend ListableTopicSerializerEventsExtension

  on(:post_created) do |post, opts, user|
    event_creator = DiscourseEvents::EventCreator.new(post, opts, user)
    event_creator.create
  end

  on(:approved_post) do |reviewable, post|
    event = reviewable.payload["event"]

    if (
         event.present? && event["event_start"].present? && event["event_start"].is_a?(Numeric) &&
           event["event_start"] != 0
       )
      topic = post.topic
      event.each { |k, v| topic.custom_fields[k] = v }

      topic.save_custom_fields(true)
    end
  end

  PostRevisor.track_topic_field(:event) do |tc, event|
    event_revisor = DiscourseEvents::EventRevisor.new(tc, event)
    event_revisor.revise!
  end

  NewPostManager.add_handler(1) do |manager|
    if manager.args["event"] && NewPostManager.post_needs_approval?(manager) &&
         NewPostManager.is_first_post?(manager)
      if NewPostManager.respond_to?(:add_plugin_payload_attribute)
        NewPostManager.add_plugin_payload_attribute("event")
      end
    end

    nil
  end

  add_to_class(:topic_query, :list_agenda) do
    @options[:unordered] = true
    @options[:list] = "agenda"

    opts = { remove_past: SiteSetting.events_remove_past_from_agenda }

    opts[:status] = "open" if SiteSetting.events_agenda_filter_closed

    create_list(:agenda, {}, event_results(opts))
  end

  add_to_class(:topic_query, :list_calendar) do
    @options[:unordered] = true
    @options[:list] = "calendar"

    opts = {
      limit: false,
      include_excerpt: true,
      remove_past: SiteSetting.events_remove_past_from_calendar,
    }

    opts[:status] = "open" if SiteSetting.events_calendar_filter_closed

    create_list(:calendar, {}, event_results(opts))
  end

  add_to_class(:topic_query, :event_results) do |options = {}|
    topics =
      default_results(options).joins(
        "INNER JOIN topic_custom_fields
              ON topic_custom_fields.topic_id = topics.id
              AND topic_custom_fields.name = 'event_start'
              AND topic_custom_fields.value <> ''",
      )

    DiscourseEvents::List.sorted_filters.each do |filter|
      topics = filter[:block].call(topics, @options)
    end

    if options[:remove_past]
      topics =
        topics.where(
          "topics.id in (
        SELECT topic_id FROM topic_custom_fields
        WHERE (name = 'event_start' OR name ='event_end')
        AND value > '#{Time.now.to_i}'
      )",
        )
    end

    topics =
      topics.reorder(
        "(
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
      ) ASC",
      ) if [nil, "default"].include?(@options[:order])

    topics.each { |t| t.include_excerpt = true } if options[:include_excerpt]

    topics
  end

  register_topic_view_posts_filter(:start) do |topics, query|
    if query.options[:start]
      topics.where(
        "topics.id in (
        SELECT topic_id FROM topic_custom_fields
        WHERE (name = 'event_start' OR name = 'event_end')
        AND value >= '#{query.options[:start].to_datetime.beginning_of_day.to_i}'
      )",
      )
    else
      topics
    end
  end

  register_topic_view_posts_filter(:end) do |topics, query|
    if query.options[:end]
      topics.where(
        "topics.id in (
        SELECT topic_id FROM topic_custom_fields
        WHERE (name = 'event_start' OR name = 'event_end')
        AND value <= '#{query.options[:end].to_datetime.end_of_day.to_i}'
      )",
      )
    else
      topics
    end
  end

  Post.has_one :event_connection,
               class_name: "DiscourseEvents::EventConnection",
               dependent: :destroy
  Guardian.prepend EventsGuardianExtension

  TopicView.attr_writer :posts
  TopicView.on_preload do |topic_view|
    if SiteSetting.events_enabled
      topic_view.posts = topic_view.posts.includes({ event_connection: :event })
    end
  end

  # The discourse-calendar plugin uses "event" on the post model
  add_to_serializer(
    :post,
    :connected_event,
    include_condition: -> { SiteSetting.events_enabled && object.event_connection.present? },
  ) do
    DiscourseEvents::PostEventSerializer.new(
      object.event_connection.event,
      scope: scope,
      root: false,
    ).as_json
  end

  add_to_class(:guardian, :can_manage_events?) do
    return false unless SiteSetting.events_enabled

    is_admin? || (SiteSetting.events_allow_moderator_management && is_staff?)
  end

  add_to_serializer(:current_user, :can_manage_events) { scope.can_manage_events? }

  add_model_callback(:user, :after_initialize) do
    self
      .class
      .define_method(:can_act_on_discourse_post_event?) do |event|
        return false if event.post.event_connection

        # "super" doesn't work here so this is lifted directly from discourse-calendar
        return @can_act_on_discourse_post_event if defined?(@can_act_on_discourse_post_event)
        @can_act_on_discourse_post_event =
          begin
            return true if staff?
            can_create_discourse_post_event? && Guardian.new(self).can_edit_post?(event.post)
          rescue StandardError
            false
          end
      end
  end
end

on(:locations_ready) do
  Locations::Map.add_list_filter do |topics, options|
    if SiteSetting.events_remove_past_from_map
      topics =
        topics.where(
          "NOT EXISTS (SELECT * FROM topic_custom_fields
                                         WHERE topic_id = topics.id
                                         AND name = 'event_start')
                             OR topics.id in (
                                SELECT topic_id FROM topic_custom_fields
                                WHERE (name = 'event_start' OR name = 'event_end')
                                AND value > '#{Time.now.to_i}')",
        )
    end

    topics
  end
end

on(:custom_wizard_ready) do
  if defined?(CustomWizard) == "constant" && CustomWizard.class == Module
    CustomWizard::Field.register("event", "discourse-events")
    CustomWizard::Action.register_callback(
      :before_create_topic,
    ) do |params, wizard, action, submission|
      if action["add_event"]
        event =
          CustomWizard::Mapper.new(
            inputs: action["add_event"],
            data: submission&.fields_and_meta,
            user: wizard.user,
          ).perform

        if event["start"].present?
          event_params = { event_start: event["start"].to_datetime.to_i }

          event_params["event_end"] = event["end"].to_datetime.to_i if event["end"].present?
          event_params["event_all_day"] = event["all_day"] === "true" if event["all_day"].present?
          event_params["event_timezone"] = event["timezone"] if event["timezone"].present?
          event_params["event_rsvp"] = event["rsvp"] if event["rsvp"].present?
          event_params["event_going_max"] = event["going_max"] if event["going_max"].present?
          event_params["event_going"] = User.where(username: event["going"]).pluck(:id) if event[
            "going"
          ].present?
          event_params["event_version"] = 1

          params[:topic_opts] ||= {}
          params[:topic_opts][:custom_fields] ||= {}
          params[:topic_opts][:custom_fields].merge!(event_params)
        end
      end

      params
    end
  end
end

on(:user_destroyed) do |user|
  user_id = user.id
  topic_ids = TopicCustomField.where(name: "event_going").pluck(:topic_id)
  topics = Topic.where(id: topic_ids) if topic_ids.present?

  if topics
    topics.each do |topic|
      rsvp_array = topic.custom_fields["event_going"] || []
      rsvp_array.delete(user.id)
      topic.custom_fields["event_going"] = rsvp_array
      topic.save_custom_fields(true)
    end
  end
end
