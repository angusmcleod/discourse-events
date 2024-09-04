# frozen_string_literal: true

module DiscourseEvents
  class PublishManager
    attr_reader :post
    attr_accessor :publisher, :publication_type, :connections, :event_data, :published_events

    def initialize(post, publication_type)
      @post = post
      @publication_type = publication_type
      @connections = []
      @published_events = {}
    end

    def ready?
      publisher.present? && connections.present?
    end

    def perform
      @publisher = get_publisher

      setup_connections

      return false unless ready?
      return false unless publish_events

      send("#{publication_type}_event")
    end

    def self.perform(post, publication_type)
      new(post, publication_type).perform
    end

    protected

    def create_event
      event = nil

      ActiveRecord::Base.transaction do
        event = Event.create!(event_data.create_params)

        connections.each do |connection|
          if published_events[connection.id].present?
            params = get_event_connection_params(event, connection)
            EventConnection.create!(params)
          end
        end

        publisher.after_publish(post, event)
      end

      event.present? ? event : false
    end

    def update_event
      ActiveRecord::Base.transaction { post.topic.event.update!(event_data.update_params) }
    end

    def destroy_event
      ActiveRecord::Base.transaction { post.topic.event.destroy! }
    end

    def setup_connections
      if publication_type == "create"
        ## We inherent the category connections on create
        post.topic&.category&.discourse_events_connections&.each do |connection|
          next unless connection.publish?
          @connections << connection
        end
      end

      if %w[update destroy].include?(publication_type)
        ## We only update or destroy the established connections.
        post.event_connections.each do |event_connection|
          connection = event_connection.connection
          next unless connection.publish?
          @connections << connection
        end
      end
    end

    def publish_events
      @event_data = publisher.get_event_data(post)
      return false unless event_data&.valid?
      publish_event_to_connection_sources
      @published_events.present?
    end

    def publish_event_to_connection_sources
      connections.each do |connection|
        publisher.setup_provider(connection.source.provider)
        event = publisher.send("#{publication_type}_event", event_data)
        @published_events[connection.id] ||= []
        @published_events[connection.id] << event if event.present?
      end
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

    def get_event_connection_params(event, connection)
      params = {
        event_id: event.id,
        connection_id: connection.id,
        topic_id: post.topic.id,
        post_id: post.id,
        client: connection.client,
      }
      params[:series_id] = event.series_id if event.series_id
      params
    end
  end
end
