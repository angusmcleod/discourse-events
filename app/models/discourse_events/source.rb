# frozen_string_literal: true

module DiscourseEvents
  class Source < ActiveRecord::Base
    self.table_name = "discourse_events_sources"

    SOURCE_OPTIONS ||= {
      developer: {
        uri: /./,
      },
      icalendar: {
        uri: URI.regexp,
      },
      eventbrite: {
        organization_id: /\d/,
      },
      meetup: {
        group_urlname: /[a-z]/,
      },
      humanitix: {
      },
      eventzilla: {
      },
      outlook: {
        user_id: /[0-9a-zA-Z]/,
        calendar_id: /[0-9a-zA-Z=-]/,
      },
      google: {
        calendar_id: /[0-9a-zA-Z=-]/,
      },
    }

    FIXED_SOURCE_OPTIONS ||= { icalendar: { expand_recurrences: true } }

    IMPORT_PERIODS ||= {
      "5_minutes": 300,
      "30_minutes": 1800,
      "1_hour": 3600,
      "1_day": 86_400,
      "1_week": 604_800,
    }.as_json

    belongs_to :provider, foreign_key: "provider_id", class_name: "DiscourseEvents::Provider"

    has_many :event_sources, foreign_key: "source_id", class_name: "DiscourseEvents::EventSource"
    has_many :events, through: :event_sources, class_name: "DiscourseEvents::Event"
    has_many :connections,
             foreign_key: "source_id",
             class_name: "DiscourseEvents::Connection",
             dependent: :destroy
    has_many :filters,
             -> { where(model_type: "DiscourseEvents::Source") },
             foreign_key: "model_id",
             class_name: "DiscourseEvents::Filter",
             dependent: :destroy

    validates_format_of :name, with: /\A[a-z0-9\_]+\Z/i
    validates :provider, presence: true
    validates :import_period,
              inclusion: {
                in: IMPORT_PERIODS.values,
                message: "%{value} is not a valid import period",
              },
              allow_nil: true
    validate :valid_source_options?

    after_commit :enqueue_import, if: :saved_change_to_import_period?

    enum sync_type: { import: 0, import_publish: 1, publish: 2 }

    def ready?
      provider.authenticated?
    end

    def import?
      sync_type == "import" || sync_type == "import_publish"
    end

    def publish?
      sync_type == "import_publish" || sync_type == "publish"
    end

    def source_options_hash
      if source_options.present?
        JSON.parse(source_options).symbolize_keys
      else
        {}
      end
    end

    def source_options_with_fixed
      opts = source_options_hash

      if fixed_opts = FIXED_SOURCE_OPTIONS[self.provider.provider_type.to_sym]
        fixed_opts.each { |key, value| opts[key] = value }
      end

      opts
    end

    def supports_series
      self.provider.provider_type.to_sym === :icalendar
    end

    def from_time
      @from_time ||=
        begin
          filter =
            filters.find_by(
              query_column: DiscourseEvents::Filter.query_columns[:start_time],
              query_operator: DiscourseEvents::Filter.query_operators[:greater_than],
            )
          filter ? filter.query_value.to_datetime : nil
        end
    end

    def to_time
      @to_time ||=
        begin
          filter =
            filters.find_by(
              query_column: DiscourseEvents::Filter.query_columns[:start_time],
              query_operator: DiscourseEvents::Filter.query_operators[:less_than],
            )
          filter ? filter.query_value.to_datetime : nil
        end
    end

    def match_name
      @match_name ||=
        begin
          filter =
            filters.find_by(
              query_column: DiscourseEvents::Filter.query_columns[:name],
              query_operator: DiscourseEvents::Filter.query_operators[:like],
            )
          filter ? filter.query_value : nil
        end
    end

    def after_import
      connections.each do |connection|
        DiscourseEvents::SyncManager.sync_connection(connection) if connection.auto_sync
      end
      enqueue_import
    end

    def enqueue_import
      Jobs.cancel_scheduled_job(:discourse_events_import_source, source_id: self.id)
      if import_period.present?
        Jobs.enqueue_in(import_period, :discourse_events_import_source, source_id: self.id)
      end
    end

    private

    def valid_source_options?
      return true if self.source_options.nil?

      unless valid_json?(self.source_options)
        begin
          self.source_options = self.source_options.to_json
        rescue JSON::ParserError => e
          errors.add(:source_options, "are not valid")
        end
      end

      return false if errors.present?

      invalid =
        invalid_options(
          self.source_options_hash,
          SOURCE_OPTIONS[self.provider.provider_type.to_sym],
        )
      errors.add(:source_options, "invalid: #{invalid.join(",")}") if invalid.any?
    end

    def invalid_options(opts, valid_options)
      opts.reduce([]) do |result, (key, value)|
        match = valid_options[key.to_sym]
        result << key if !match || value !~ match
        result
      end
    end

    def valid_json?(json)
      JSON.parse(json)
      true
    rescue JSON::ParserError => e
      false
    end
  end
end

# == Schema Information
#
# Table name: discourse_events_sources
#
#  id             :bigint           not null, primary key
#  name           :string           not null
#  provider_id    :bigint           not null
#  source_options :json
#  from_time      :datetime
#  to_time        :datetime
#  status         :string
#  taxonomy       :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  sync_type      :integer
#
# Indexes
#
#  index_discourse_events_sources_on_name         (name) UNIQUE
#  index_discourse_events_sources_on_provider_id  (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => discourse_events_providers.id)
#
