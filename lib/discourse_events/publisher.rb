# frozen_string_literal: true

module DiscourseEvents
  class Publisher
    attr_reader :logger
    attr_accessor :provider

    def setup_provider(_provider)
      OmniEvent::Builder.new { provider _provider.provider_type, _provider.options }

      @provider = _provider
    end

    def create_event(data: nil, opts: {})
      OmniEvent.create_event(provider.provider_type, omnievent_opts("create", data, opts))
    end

    def update_event(data: nil, opts: {})
      OmniEvent.update_event(provider.provider_type, omnievent_opts("update", data, opts))
    end

    def destroy_event(data: nil, opts: {})
      OmniEvent.destroy_event(provider.provider_type, omnievent_opts("destroy", data, opts))
    end

    def get_event_data(post)
      raise NotImplementedError
    end

    protected

    def omnievent_opts(type, data, opts)
      opts.merge(event: event_hash(type, data))
    end

    def event_hash(type, data)
      raise ArgumentError.new "No event data" unless data.is_a?(EventData)
      event = data.event_hash(type, provider.provider_type)
      raise ArgumentError.new "Invalid event data" unless event.valid?
      event
    end
  end
end
