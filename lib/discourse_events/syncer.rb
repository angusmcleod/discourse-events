# frozen_string_literal: true

module DiscourseEvents
  class Syncer
    attr_reader :user, :source, :client, :logger
    attr_accessor :opts

    def initialize(user: nil, source: nil, client: nil)
      @user = user
      @source = source
      @client = client
      @logger = Logger.new(:sync)
    end

    def ready?
      source.user.present?
    end

    def sync(_opts = {})
      @opts = _opts

      updated_topics = update_events
      created_topics = create_events

      if one_topic_per_series
        updated_series_topics = update_series_events_topics
        created_topics += updated_series_topics[:created_topics]
        updated_topics += updated_series_topics[:updated_topics]
      end

      { created_topics: created_topics, updated_topics: updated_topics }
    end

    def create_topic(event, topic_opts = {})
      topic = create_client_topic(event, topic_opts)
      raise ActiveRecord::Rollback if topic.blank?
      create_event_topic(event, topic)
      update_registrations(topic, event)
      topic
    end

    def update_topic(topic, event, add_raw: nil)
      topic = update_client_topic(topic, event, add_raw: add_raw)
      raise ActiveRecord::Rollback if topic.blank?
      update_registrations(topic, event)
      topic
    end

    def connect_topic(topic, event)
      return false unless can_connect_topic?(topic, event)
      update_topic(topic, event, add_raw: true)
    end

    def update_registrations(topic, event)
      ensure_registration_users(event)
      update_client_registrations(topic, event)
    end

    def create_post(event, topic_opts = {})
      topic_opts = { title: event.name }.merge(topic_opts)
      topic_opts[:category] = source.category.id if source&.category_id

      PostCreator.create!(
        user,
        topic_opts: topic_opts,
        raw: post_raw(event),
        skip_validations: true,
        skip_event_publication: true,
      )
    end

    def create_event_topic(event, topic)
      params = { event_id: event.id, topic_id: topic.id, client: client }
      params[:series_id] = event.series_id if event.series_id
      EventTopic.create!(params)
    end

    def ensure_event_topic(event, topic)
      unless EventTopic.exists?(event_id: event.id, topic_id: topic.id)
        create_event_topic(event, topic)
      end
    end

    def can_connect_topic?(topic, event)
      raise NotImplementedError
    end

    def create_client_topic(event, topic_opts = {})
      raise NotImplementedError
    end

    def connect_client_topic(topic, event)
      raise NotImplementedError
    end

    def update_client_topic(topic, event, add_raw: false)
      raise NotImplementedError
    end

    def update_client_registrations(topic, event)
      raise NotImplementedError
    end

    def post_raw(event, post: nil, add_raw: false)
      raise NotImplementedError
    end

    def update_events
      topics_updated = []

      synced_events
        .includes(event_topics: %i[topic])
        .each do |event|
          ActiveRecord::Base.transaction do
            event
              .event_topics
              .where(client: client)
              .each do |et|
                topic = update_topic(et.topic, event)
                next unless topic
                topics_updated << topic.id
              end
          end
        end

      topics_updated
    end

    def create_events
      topics_created = []

      unsynced_events.each do |event|
        ActiveRecord::Base.transaction do
          topic = create_topic(event)
          next unless topic
          topics_created << topic.id
        end
      end

      topics_created
    end

    def update_series_events_topics
      topics_updated = []
      topics_created = []

      series_events.each do |event|
        topic = event.series_topics.first

        ActiveRecord::Base.transaction do
          if topic.present?
            ensure_event_topic(event, topic)
            topic = update_topic(topic, event)
            topics_updated << topic.id
          else
            topic = create_topic(event)
            topics_created << topic.id
          end
        end
      end

      { updated_topics: topics_updated, created_topics: topics_created }
    end

    def synced_events
      standard_events.where("discourse_events_events.id IN (#{event_topics_sql})")
    end

    def unsynced_events
      standard_events.where("discourse_events_events.id NOT IN (#{event_topics_sql})")
    end

    def event_topics_sql
      "SELECT event_id FROM discourse_events_event_topics WHERE topic_id IS NOT NULL"
    end

    def source_events
      @source_events ||=
        begin
          events =
            Event.joins(:event_sources).where(
              "discourse_events_event_sources.source_id = ?",
              source.id,
            )
          source.filters.each do |filter|
            events = events.where("#{filter.sql_column} #{filter.sql_operator} ?", filter.sql_value)
          end
          events
        end
    end

    def standard_events
      @standard_events ||=
        begin
          events = source_events
          events = events.where("discourse_events_events.series_id IS NULL") if one_topic_per_series
          events
        end
    end

    def series_events
      # Compare DiscourseEvents::Event::FUTURE_SERIES_EVENTS_SQL
      @series_events ||=
        source_events
          .select("DISTINCT ON (series_id) discourse_events_events.*")
          .where(
            "discourse_events_events.series_id IS NOT NULL AND discourse_events_events.start_time > ?",
            Time.now,
          )
          .order("discourse_events_events.series_id, discourse_events_events.start_time ASC")
    end

    def log(type, message)
      logger.send(type.to_s, message)
    end

    def one_topic_per_series
      source.supports_series && SiteSetting.events_one_event_per_series
    end

    def ensure_registration_users(event)
      event.registrations.each do |registration|
        next if registration.user.present?
        user = find_or_create_user(registration)
        next unless user.present?
        registration.update(user_id: user.id)
      end
    end

    def find_or_create_user(registration)
      user = User.find_by_email(registration.email)

      unless user
        begin
          user =
            User.create!(
              email: registration.email,
              username: UserNameSuggester.suggest(registration.name.presence || registration.email),
              name: registration.name || User.suggest_name(registration.email),
              staged: true,
            )
        rescue PG::UniqueViolation,
               ActiveRecord::RecordNotUnique,
               ActiveRecord::RecordInvalid => error
          message = I18n.t("log.sync_failed_to_create_registration_user", email: registration.email)
          log(:error, message)
        end
      end

      user
    end
  end
end
