# frozen_string_literal: true

module DiscourseEvents
  class Syncer
    attr_reader :user, :source, :logger

    attr_accessor :opts

    def initialize(user, source = nil)
      @user = user
      @source = source
      @logger = Logger.new(:sync)
    end

    def ready?
      source.user.present?
    end

    def create_topic(event)
      raise NotImplementedError
    end

    def connect_topic(topic, event)
      raise NotImplementedError
    end

    def update_topic(topic, event)
      raise NotImplementedError
    end

    def post_raw(event, post: nil, add_raw: false)
      raise NotImplementedError
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

    def update_events
      topics_updated = []

      synced_events
        .includes(event_topics: %i[topic])
        .each do |event|
          ActiveRecord::Base.transaction do
            event
              .event_topics
              .where(client: source.client)
              .each { |et| topics_updated << _update_topic(et.topic, event) }
          end
        end

      topics_updated
    end

    def create_events
      topics_created = []

      unsynced_events.each do |event|
        ActiveRecord::Base.transaction { topics_created << _create_topic(event) }
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
            topics_updated << _update_topic(topic, event)
          else
            topics_created << _create_topic(event)
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

    def create_post(event, topic_opts = {})
      topic_opts = { title: event.name }.merge(topic_opts)

      topic_opts[:category] = source.category.id if source.category_id

      PostCreator.create!(
        user,
        topic_opts: topic_opts,
        raw: post_raw(event),
        skip_validations: true,
        skip_event_publication: true,
      )
    end

    def create_event_topic(event, topic)
      params = { event_id: event.id, topic_id: topic.id, client: source.client }
      params[:series_id] = event.series_id if event.series_id
      EventTopic.create!(params)
    end

    def ensure_event_topic(event, topic)
      unless EventTopic.exists?(event_id: event.id, topic_id: topic.id)
        create_event_topic(event, topic)
      end
    end

    def one_topic_per_series
      source.supports_series && SiteSetting.events_one_event_per_series
    end

    def _create_topic(event)
      topic = create_topic(event)
      raise ActiveRecord::Rollback if topic.blank?
      create_event_topic(event, topic)
      topic.id
    end

    def _update_topic(topic, event)
      topic = update_topic(topic, event)
      raise ActiveRecord::Rollback if topic.blank?
      topic.id
    end
  end
end
