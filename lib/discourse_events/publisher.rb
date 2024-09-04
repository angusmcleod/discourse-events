# frozen_string_literal: true

module DiscourseEvents
  class Publisher
    attr_reader :logger
    attr_accessor :provider

    def initialize
      @logger = Logger.new(:publisher)
      OmniEvent.config.logger = @logger
    end

    def setup_provider(_provider)
      OmniEvent::Builder.new { provider _provider.provider_type, _provider.options }

      @provider = _provider
    end

    def create_event(event_data)
      OmniEvent.create_event(provider.provider_type, event: event_data.create_event_hash)
    end

    def update_event(event_data)
      OmniEvent.update_event(provider.provider_type, event: event_data.update_event_hash)
    end

    def destroy_event(event_data)
      OmniEvent.destroy_event(provider.provider_type, event: event_data.destroy_event_hash)
    end

    def get_event_data(post)
      raise NotImplementedError
    end

    def after_publish(post, event)
      raise NotImplementedError
    end

    protected

    def log(type, message)
      logger.send(type.to_s, message)
    end

    def create_event_hash(event_data)
      OmniEvent::EventHash.new(
        provider: provider.provider_type,
        data: event_data.data,
        metadata: event_data.metadata,
      )
    end
  end
end
