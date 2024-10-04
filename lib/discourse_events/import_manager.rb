# frozen_string_literal: true

module DiscourseEvents
  class ImportManager
    include Subscription

    attr_reader :source, :logger
    attr_accessor :imported_event_uids, :created_event_uids, :updated_event_uids

    def initialize(source)
      @source = source
      @logger = Logger.new(:import)
    end

    def ready?
      @ready ||= false
    end

    def setup
      return false unless subscribed? && source&.import_ready?
      _provider = source.provider
      ::OmniEvent.config.logger = @logger
      ::OmniEvent::Builder.new { provider _provider.provider_type, _provider.options }
      @ready = true
    end

    def import(opts = {})
      return false unless ready?

      opts.merge!(debug: Rails.env.development?)

      imported_events = {}
      ::OmniEvent
        .list_events(source.provider.provider_type, opts)
        .each do |imported_event|
          data = imported_event.data.to_h.with_indifferent_access
          data[:status] = "published" if data[:status].blank?
          data[:series_id] = imported_event.metadata.series_id
          data[:occurrence_id] = imported_event.metadata.occurrence_id
          data[:registrations] = imported_event.associated_data.registrations

          imported_events[imported_event.metadata.uid] = data
        end

      @imported_event_uids = imported_events.keys
      @created_event_uids = []
      @updated_event_uids = []

      if imported_events.present?
        imported_events.each do |uid, data|
          event_source = source.event_sources.find_by(uid: uid)

          if event_source
            event_source.event.update!(data.except(:registrations))

            updated_event_uids << event_source.uid
          else
            ActiveRecord::Base.transaction do
              event = Event.create!(data.except(:registrations))
              event_source = EventSource.create!(uid: uid, event_id: event.id, source_id: source.id)
            end

            created_event_uids << event_source.uid
          end

          if event_source.event.id && data[:registrations].present?
            registrations =
              data[:registrations].map do |registration|
                result = {
                  event_id: event_source.event.id,
                  email: registration[:email],
                  uid: registration[:uid],
                  name: registration[:name],
                }
                if registration[:status] &&
                     EventRegistration.statuses.keys.include?(registration[:status])
                  result[:status] = EventRegistration.statuses[registration[:status]]
                end
                result
              end
            EventRegistration.upsert_all(registrations, unique_by: %i[email])
          end
        end
      end

      if source
        message =
          I18n.t(
            "log.import_finished",
            provider_type: source.provider.provider_type,
            events_count: imported_event_uids.count,
            created_count: created_event_uids.count,
            updated_count: updated_event_uids.count,
          )
        logger.send(:info, message)

        source.after_import
      end
    end

    def self.import(source)
      manager = self.new(source)
      manager.setup
      return unless manager.ready?

      opts = source.source_options_with_fixed
      opts[:from_time] = source.from_time if source.from_time.present?
      opts[:to_time] = source.to_time if source.to_time.present?
      opts[:match_name] = source.match_name if source.match_name.present?

      manager.import(opts)
    end

    def self.import_source(source_id)
      source = Source.find_by(id: source_id)
      return unless source.present?
      import(source)
    end

    def self.import_all_sources
      Source.all.each { |source| import(source) }
    end
  end
end
