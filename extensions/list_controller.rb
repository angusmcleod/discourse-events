# frozen_string_literal: true

module ListControllerEventsExtension
  USER_API_KEY ||= "user_api_key"
  USER_API_CLIENT_ID ||= "user_api_client_id"
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

require 'icalendar/tzinfo'
class ::ListController
  skip_before_action :ensure_logged_in, only: [:calendar_ics, :calendar_feed]
  skip_before_action :set_category, only: [
    :agenda_feed,
    :calendar_ics,
    :calendar_feed,
  ]

  def agenda_feed
    self.send('event_ics', name: 'agenda')
  end

  def calendar_feed
    self.send('event_feed', name: 'calendar')
  end

  def calendar_ics
    self.send('event_ics', name: 'calendar')
  end

  def agenda_feed_category
    self.send('event_feed', name: 'agenda')
  end

  def calendar_feed_category
    self.send('event_feed', name: 'calendar')
  end

  def calendar_ics_category
    self.send('event_ics', name: 'calendar')
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

    tzid = params[:time_zone] || (SiteSetting.respond_to?(:events_timezone_default) && SiteSetting.events_timezone_default.present? && SiteSetting.events_timezone_default) || "Etc/UTC"
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
        event = DiscourseEvents::Helper.localize_event(t.event, tzid)
        timezone = tz.ical_timezone event[:start]

        ## to do: check if working later
        if event[:format] == :date_only
          event[:start] = event[:start].to_date.strftime "%Y%m%d"
          event[:end] = (event[:end].to_date + 1).strftime "%Y%m%d" if event[:end]
        end

        if event[:going].present?
          going_emails = User.where(username: event[:going]).map(&:email)
        end

        cal.event do |e|
          e.dtstart = Icalendar::Values::DateOrDateTime.new(event[:start], 'tzid' => tzid).call
          if event[:end]
            e.dtend = Icalendar::Values::DateOrDateTime.new(event[:end], 'tzid' => tzid).call
          end
          e.summary = t.title
          e.description = t.url << "\n\n" << t.excerpt #add url to event body
          e.url = t.url #most calendar clients don't display this field
          e.uid = t.id.to_s + "@" + Discourse.base_url.sub(/^https?\:\/\/(www.)?/, '')
          e.sequence = event[:version]

          if going_emails
            going_emails.each do |email|
              e.append_attendee "mailto:#{email}"
            end
          end
        end
      end
    end

    cal.publish

    render body: cal.to_ical, formats: [:ics], content_type: Mime::Type.lookup("text/calendar") unless performed?
  end

  prepend ListControllerEventsExtension
end
