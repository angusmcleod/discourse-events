# frozen_string_literal: true

module DiscourseEvents
  class PublishManager
    include Subscription

    attr_reader :post, :logger
    attr_accessor :publisher, :publication_type

    def initialize(post, publication_type)
      @post = post
      @publication_type = publication_type
      @logger = Logger.new(:publish)
    end

    def ready?
      publisher.present? && subscription_manager.supports_publish?
    end

    def perform
      @publisher = get_publisher
      return false unless ready?

      send("#{publication_type}_event")
    end

    def self.perform(post, publication_type)
      new(post, publication_type).perform
    end

    protected

    def create_event
      return false if post.topic.event_record.present?

      data = publisher.get_event_data(post)
      return false unless data&.valid?

      event = Event.create!(data.create_params)

      sources = []

      post.topic&.category&.discourse_events_sources&.each do |source|
        next unless source.publish?
        sources << source
      end
      return unless sources.present?

      published_events = {}

      sources.each do |source|
        publisher.setup_provider(source.provider)

        begin
          published_event = publisher.create_event(data: data, opts: source.source_options_hash)
        rescue => error
          logger.error(error.message)
        end

        published_events[source.id] = published_event if published_event.present?
      end

      sources.each do |source|
        published_event = published_events[source.id]

        if published_event.present?
          params = { uid: published_event.metadata.uid, source_id: source.id, event_id: event.id }
          EventSource.create!(params)
        end
      end

      event.present? ? event : false
    end

    def update_event
      data = publisher.get_event_data(post)
      return false unless data&.valid?

      event = post.topic.event_record
      return false unless event

      if event.event_sources
        event.event_sources.each do |event_source|
          source = event_source.source
          publisher.setup_provider(source.provider)

          source_data = data.dup
          source_data.uid = event_source.uid

          begin
            publisher.update_event(data: source_data, opts: source.source_options_hash)
          rescue => error
            logger.error(error.message)
          end
        end
      end

      event.update!(data.update_params)
    end

    def destroy_event
      event = post.topic.event_record
      return false unless event

      if event.event_sources
        event.event_sources.each do |event_source|
          source = event_source.source
          publisher.setup_provider(source.provider)

          source_data = Publisher::EventData.new(uid: event_source.uid)

          begin
            publisher.destroy_event(data: source_data, opts: source.source_options_hash)
          rescue => error
            logger.error(error.message)
          end
        end
      end

      event.destroy!
    end

    def get_publisher
      client = detect_client
      return false unless Source::CLIENT_NAMES.include?(client)

      publisher = "DiscourseEvents::Publisher::#{client.camelize}".constantize.new
      return false unless publisher.ready?

      publisher
    end

    def detect_client
      if post.topic.has_event?
        "discourse_events"
      elsif post.respond_to?(:event) && post.event.present?
        "discourse_calendar"
      else
        nil
      end
    end
  end
end
