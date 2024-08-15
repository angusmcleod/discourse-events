# frozen_string_literal: true

module DiscourseEvents
  class ImportManager
    attr_reader :provider, :source, :logger

    def initialize(provider, source)
      @provider = provider
      @source = source
      @logger = Logger.new(:import)

      OmniEvent.config.logger = @logger
      OmniEvent::Builder.new { provider provider.provider_type, provider.options }
    end

    def import(opts = {})
      opts.merge!(debug: Rails.env.development?)

      events =
        ::OmniEvent
          .list_events(provider.provider_type, opts)
          .map do |e|
            data = e.data.to_h.with_indifferent_access

            data[:uid] = e.metadata.uid
            data[:status] = "published" if data[:status].blank?
            data[:source_id] = source.id
            data[:provider_id] = source.provider.id
            data[:series_id] = e.metadata.series_id
            data[:occurrence_id] = e.metadata.occurrence_id

            data
          end

      events_count = 0
      created_count = 0
      updated_count = 0

      if events.present?
        result =
          Event.upsert_all(
            events,
            unique_by: %i[uid provider_id],
            record_timestamps: true,
            returning: Arel.sql("(xmax = 0) AS inserted"),
          )
        events_count = events.size
        created_count = result.rows.map { |r| r[0] }.tally[true].to_i
        updated_count = events_count - created_count
      end

      if source
        message =
          I18n.t(
            "log.import_finished",
            source_name: source.name,
            events_count: events_count,
            created_count: created_count,
            updated_count: updated_count,
          )
        logger.send(:info, message)
      end

      { events_count: events_count, created_count: created_count, updated_count: updated_count }
    end

    def self.import(source)
      return unless source&.ready?
      manager = self.new(source.provider, source)

      opts = source.source_options_with_fixed
      opts[:from_time] = source.from_time if source.from_time.present?
      opts[:to_time] = source.to_time if source.to_time.present?

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
