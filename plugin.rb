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

gem 'icalendar', '2.4.1'

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
  Category.register_custom_field_type('events_min_trust_to_create', :integer)
  add_to_serializer(:basic_category, :events_enabled) { object.custom_fields['events_enabled'] }
  add_to_serializer(:basic_category, :events_agenda_enabled) { object.custom_fields['events_agenda_enabled'] }
  add_to_serializer(:basic_category, :events_calendar_enabled) { object.custom_fields['events_calendar_enabled'] }
  add_to_serializer(:basic_category, :events_agenda_filter_closed) { object.custom_fields['events_agenda_filter_closed'] }
  add_to_serializer(:basic_category, :events_event_label_no_text) { object.custom_fields['events_event_label_no_text'] }
  add_to_serializer(:basic_category, :events_min_trust_to_create) { object.events_min_trust_to_create }

  class ::Category
    def events_min_trust_to_create
      if self.custom_fields['events_min_trust_to_create'].present?
        self.custom_fields['events_min_trust_to_create'].to_i
      else
        0
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

  User.register_custom_field_type('calendar_first_day_week', :integer)
  add_to_serializer(:current_user, :calendar_first_day_week) { object.custom_fields['calendar_first_day_week'] }

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

      topic.custom_fields['event_start'] = event_start.to_datetime.to_i if event_start
      topic.custom_fields['event_end'] = event_end.to_datetime.to_i if event_end
      topic.custom_fields['event_all_day'] = event_all_day === 'true' if event_all_day
      topic.custom_fields['event_timezone'] = timezone if timezone
      topic.save!
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

  require_dependency 'topic_query'
  class ::TopicQuery
    SORTABLE_MAPPING['event'] = 'custom_fields.event_start'

    def list_agenda
      @options[:order] = 'event'
      @options[:list] = 'agenda'
      opts = {}
      opts[:status] = 'open' if SiteSetting.events_agenda_filter_closed

      create_list(:agenda, {}, event_results(opts)) do |topics|
        if SiteSetting.events_remove_past_from_agenda
          topics = topics.where("topics.id in (
            SELECT topic_id FROM topic_custom_fields
            WHERE (name = 'event_start' OR name ='event_end')
            AND value > '#{Time.now.to_i}'
          )")
        end

        topics
      end
    end

    def list_calendar
      @options[:order] = 'event'
      @options[:list] = 'calendar'
      create_list(:calendar, {}, event_results(limit: false))
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

      topics
    end
  end

  ListController.class_eval do
    skip_before_action :ensure_logged_in, only: [:calendar_ics, :agenda_ics]

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

      cal = Icalendar::Calendar.new
      cal.x_wr_calname = calendar_name
      @topic_list = TopicQuery.new(nil, list_opts).list_calendar

      @topic_list.topics.each do |t|
        if t.event && t.event[:start]
          localized_event = CalendarEvents::Helper.localize_event(t.event, params[:time_zone])

          cal.event do |e|
            e.dtstart = localized_event[:start]
            e.dtend = localized_event[:end]
            e.summary = t.title
            e.description = t.excerpt
            e.url = calendar_url
          end
        end
      end

      cal.publish

      render plain: cal.to_ical, formats: [:ics] unless performed?
    end
  end

  Discourse::Application.routes.prepend do
    get "calendar.ics" => "list#calendar_ics", format: :ics, protocol: :webcal
    get "agenda.ics" => "list#agenda_ics", format: :ics, protocol: :webcal
    get "c/:category/l/calendar.ics" => "list#calendar_ics", format: :ics, protocol: :webcal
    get "c/:category/l/agenda.ics" => "list#agenda_ics", format: :ics, protocol: :webcal

    get "c/:category/l/calendar.rss" => "list#calendar_feed", format: :rss
    get "c/:category/l/agenda.rss" => "list#agenda_feed", format: :rss
  end

  Rails.configuration.paths['app/views'].unshift(Rails.root.join('plugins', 'discourse-events', 'app/views'))

  module UserNotificationsEventExtension
    protected def send_notification_email(opts)
      post = opts[:post]
      if post && post.topic.event
        @event = post.topic.event
      end
      super(opts)
    end
  end

  module InviteMailerEventExtension
    def send_invite(invite)
      topic = invite.topics.order(:created_at).first
      if topic && topic.event
        @event = topic.event
      end
      super(invite)
    end
  end

  module BuildEmailHelperExtension
    def build_email(*builder_args)
      if builder_args[1] && @event
        builder_args[1][:event] = @event
      end
      super(*builder_args)
    end
  end

  require_dependency 'user_notifications'
  class ::UserNotifications
    prepend UserNotificationsEventExtension
    prepend BuildEmailHelperExtension
  end

  require_dependency 'invite_mailer'
  class ::InviteMailer
    prepend InviteMailerEventExtension
    prepend BuildEmailHelperExtension
  end

  module MessageBuilderExtension
    def html_part
      ## We need to force plaintext for all invites for now (non-user invites are already plaintext)
      ## as there's no straightfoward way to get the event in the invite template without significant overriding
      return if @opts[:event] && invite_template

      super
    end

    def body
      body = super

      if @opts[:event]
        event = @opts[:event]
        localized_event = CalendarEvents::Helper.localize_event(event)

        event_str = "&#128197; #{I18n.l(localized_event[:start], format: :long)}"

        if localized_event[:end]
          event_str << " — #{I18n.l(localized_event[:end], format: :long)}"
        end

        event_str << "  (GMT+#{localized_event[:offset]}) #{localized_event[:timezone]}"

        if invite_template
          topic_type_match = Regexp.new("#{I18n.t('event_email.topic_type_match')}")
          topic_type_sub = I18n.t('event_email.topic_type_sub')

          body.gsub!(topic_type_match, topic_type_sub)

          pre_str, post_str = body.slice!(0...(body.rindex('*') + 1)), body

          body = %{
            #{pre_str}
            >
            > #{event_str}
            #{post_str}
          }
        else
          body = "#{event_str}\n\n#{body}"
        end
      end

      body
    end

    def invite_template
      invite_notification || invite_mailer
    end

    def invite_notification
      @opts[:template] === "user_notifications.user_invited_to_topic"
    end

    def invite_mailer
      @opts[:template] === "invite_mailer" || @opts[:template] === "custom_invite_mailer"
    end
  end

  class Email::MessageBuilder
    prepend MessageBuilderExtension
  end

  class UserNotifications::UserNotificationRenderer
    def localized_event(event)
      if event
        @event ||= CalendarEvents::Helper.localize_event(event)
      else
        nil
      end
    end
  end
end
