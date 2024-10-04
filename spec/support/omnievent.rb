# frozen_string_literal: true

module OmniEvent
  class KeyStore < ::Hashie::Mash
  end
  class EventHash < OmniEvent::KeyStore
  end
  class Builder
    def initialize(&block)
    end
  end
  class << self
    def create_event(provider_type, opts)
    end
    def update_event(provider_type, opts)
    end
    def destroy_event(provider_type, opts)
    end
    def list_events(provider_type, opts)
      raw_events =
        JSON.parse(
          File.open(
            File.join(File.expand_path("../", __dir__), "fixtures", "list_events.json"),
          ).read,
        ).to_h

      raw_events["events"].each_with_object([]) do |raw_event, result|
        raw_event = raw_event.with_indifferent_access

        event =
          OmniEvent::EventHash.new(
            provider: name,
            data: raw_event.slice(:start_time, :end_time, :name, :description, :url),
            metadata:
              raw_event.slice(
                :uid,
                :created_at,
                :updated_at,
                :language,
                :status,
                :taxonomies,
                :sequence,
                :series_id,
                :occurrence_id,
              ),
            associated_data: OmniEvent::EventHash.new(registrations: []),
          )

        event.data.start_time = format_time(event.data.start_time)
        event.data.end_time = format_time(event.data.end_time)
        event.metadata.created_at = format_time(event.metadata.created_at)
        event.metadata.updated_at = format_time(event.metadata.updated_at)
        event.metadata.uid = raw_event["id"]

        if raw_event["attendees"]
          event.associated_data.registrations =
            raw_event["attendees"].map do |attendee|
              OmniEvent::EventHash.new(attendee.symbolize_keys)
            end
        end

        next if opts[:from_time] && Time.parse(event.data.start_time).utc < opts[:from_time].utc
        next if opts[:to_time] && Time.parse(event.data.start_time).utc > opts[:to_time].to_time.utc

        result << event
      end
    end

    def format_time(value)
      Time.parse(value).iso8601
    end

    def config
      @config ||= OpenStruct.new(logger: nil)
    end
  end
end
