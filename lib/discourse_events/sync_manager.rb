# frozen_string_literal: true

module DiscourseEvents
  class SyncManager
    attr_reader :user, :client

    def initialize(user, client)
      if Source::CLIENT_NAMES.exclude?(client.to_s)
        raise ArgumentError.new("Must pass a valid client")
      end

      @user = user
      @client = client.to_s
    end

    def sync(source, opts = {})
      syncer = "DiscourseEvents::#{client.camelize}Syncer".constantize.new(user, source)

      client_name = client.humanize
      source_name = syncer.source.name
      category_name = syncer.source.category&.name

      unless syncer&.ready?
        message =
          I18n.t(
            "log.sync_client_not_ready",
            client_name: client_name,
            source_name: source_name,
            category_name: category_name,
          )
        syncer.log(:error, message)
        return false
      end

      result = syncer.sync

      message =
        I18n.t(
          "log.sync_finished",
          client_name: client.humanize,
          source_name: source_name,
          category_name: category_name,
          created_count: result[:created_topics].size,
          updated_count: result[:updated_topics].size,
        )
      syncer.log(:info, message)

      result
    end

    def self.sync_source_by_id(source_id)
      source = Source.find_by(id: source_id)
      return if source.blank?

      sync_source(source)
    end

    def self.sync_source(source)
      return if source.blank?

      syncer = self.new(source.user, source.client)
      syncer.sync(source)
    end

    def self.sync_all_sources
      result = { synced_sources: [], created_topics: [], updated_topics: [] }

      Source.all.each do |source|
        result[:synced_sources] << source.id

        syncer = self.new(source.user, source.client)
        sync_result = syncer.sync(source)

        result[:created_topics] += sync_result[:created_topics]
        result[:updated_topics] += sync_result[:updated_topics]
      end

      result
    end
  end
end
