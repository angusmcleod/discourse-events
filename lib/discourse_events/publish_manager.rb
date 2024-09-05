# frozen_string_literal: true

module DiscourseEvents
  class PublishManager
    attr_reader :post, :logger
    attr_accessor :publisher, :publication_type

    def initialize(post, publication_type)
      @post = post
      @publication_type = publication_type
      @logger = Logger.new(:publish)
    end

    def ready?
      publisher.present?
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
      data = publisher.get_event_data(post)
      return false unless data&.valid?

      connections = []

      post.topic&.category&.discourse_events_connections&.each do |connection|
        next unless connection.publish?
        connections << connection
      end
      return unless connections.present?

      published_events = {}

      connections.each do |connection|
        publisher.setup_provider(connection.source.provider)

        begin
          published_event =
            publisher.create_event(data: data, opts: connection.source.source_options_hash)
        rescue => error
          logger.error(error.message)
        end

        published_events[connection.id] = published_event if published_event.present?
      end

      event = nil

      ActiveRecord::Base.transaction do
        event = Event.create!(data.create_params)

        connections.each do |connection|
          published_event = published_events[connection.id]

          if published_event.present?
            params = {
              event_id: event.id,
              connection_id: connection.id,
              topic_id: post.topic.id,
              post_id: post.id,
              client: connection.client,
              external_id: published_event.metadata.uid,
            }
            params[:series_id] = event.series_id if event.series_id
            EventConnection.create!(params)
          end
        end
      end

      event.present? ? event : false
    end

    def update_event
      data = publisher.get_event_data(post)
      return false unless data&.valid?

      post
        .event_connections
        .where.not(external_id: nil)
        .each do |event_connection|
          source = event_connection.connection.source
          publisher.setup_provider(source.provider)

          connection_data = data.dup
          connection_data.uid = event_connection.external_id

          begin
            publisher.update_event(data: connection_data, opts: source.source_options_hash)
          rescue => error
            logger.error(error.message)
          end
        end

      ActiveRecord::Base.transaction { post.topic.event_record.update!(data.update_params) }
    end

    def destroy_event
      post
        .event_connections
        .where.not(external_id: nil)
        .each do |event_connection|
          source = event_connection.connection.source
          publisher.setup_provider(source.provider)

          data = Publisher::EventData.new(uid: event_connection.external_id)

          begin
            publisher.destroy_event(data: data, opts: source.source_options_hash)
          rescue => error
            logger.error(error.message)
          end
        end

      ActiveRecord::Base.transaction { post.topic.event_record.destroy! }
    end

    def get_publisher
      client = detect_client
      return false unless Connection.client_names.include?(client)

      publisher = "DiscourseEvents::Publisher::#{client.camelize}".constantize.new
      return false unless publisher.ready?

      publisher
    end

    def detect_client
      if post.topic.has_event?
        "events"
      elsif post.respond_to?(:event) && post.event.present?
        "discourse_events"
      else
        nil
      end
    end
  end
end
