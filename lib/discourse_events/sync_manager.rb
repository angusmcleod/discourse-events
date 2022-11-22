# frozen_string_literal: true

module DiscourseEvents
  class SyncManager
    attr_reader :user,
                :client

    def initialize(user, client)
      raise ArgumentError.new("Must pass a valid client") unless Connection.client_names.include?(client.to_s)

      @user = user
      @client = client.to_s
    end

    def sync(connection, opts = {})
      syncer = "DiscourseEvents::#{client.camelize}Syncer".constantize.new(user, connection)

      client_name = client.humanize
      source_name = syncer.connection.source.name
      category_name = syncer.connection.category.name

      unless syncer&.class.ready?
        message = I18n.t("log.sync_client_not_ready",
          client_name: client_name,
          source_name: source_name,
          category_name: category_name
        )
        syncer.log(:error, message)
        return false
      end

      result = syncer.sync

      message = I18n.t('log.sync_finished',
        client_name: client.humanize,
        source_name: source_name,
        category_name: category_name,
        created_count: result[:created_topics].size,
        updated_count: result[:updated_topics].size
      )
      syncer.log(:info, message)

      result
    end

    def self.sync_connection(connection_id)
      connection = Connection.find_by(id: connection_id)
      return unless connection.present?

      syncer = self.new(connection.user, connection.client)
      syncer.sync(connection)
    end

    def self.sync_all_connections
      result = {
        synced_connections: [],
        created_topics: [],
        updated_topics: []
      }

      Connection.all.each do |connection|
        result[:synced_connections] << connection.id

        syncer = self.new(connection.user, connection.client)
        sync_result = syncer.sync(connection)

        result[:created_topics] += sync_result[:created_topics]
        result[:updated_topics] += sync_result[:updated_topics]
      end

      result
    end
  end
end
