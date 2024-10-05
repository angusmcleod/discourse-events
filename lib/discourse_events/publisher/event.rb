# frozen_string_literal: true
module DiscourseEvents
  class Publisher::Event
    attr_accessor :start_time,
                  :end_time,
                  :name,
                  :description,
                  :url,
                  :uid,
                  :created_at,
                  :updated_at,
                  :language,
                  :status,
                  :taxonomies,
                  :sequence,
                  :series_id,
                  :occurrence_id,
                  :registrations

    def initialize(params = {})
      @start_time = params[:start_time]
      @end_time = params[:end_time]
      @name = params[:name]
      @description = params[:description]
      @url = params[:url]
      @uid = params[:uid]
      @created_at = params[:created_at]
      @updated_at = params[:updated_at]
      @language = params[:language]
      @status = params[:status] || "published"
      @taxonomies = params[:taxonomies]
      @sequence = params[:sequence]
      @series_id = params[:series_id]
      @occurrence_id = params[:occurrence_id]
    end

    def valid?
      @start_time.present?
    end

    def data
      { start_time: start_time, end_time: end_time, name: name, description: description, url: url }
    end

    def metadata
      {
        uid: uid,
        created_at: created_at,
        updated_at: updated_at,
        language: language,
        status: status,
        taxonomies: taxonomies,
        sequence: sequence,
        series_id: series_id,
        occurrence_id: occurrence_id,
      }
    end

    def associated_data
      { registrations: registrations }
    end

    def create_params
      {
        start_time: start_time,
        end_time: end_time,
        name: name,
        description: description,
        url: url,
        series_id: series_id,
        occurrence_id: occurrence_id,
      }
    end

    def update_params
      {
        start_time: start_time,
        end_time: end_time,
        name: name,
        description: description,
        url: url,
        series_id: series_id,
        occurrence_id: occurrence_id,
      }.compact
    end

    def event_hash(action, provider_type)
      send("#{action}_event_hash", provider_type)
    end

    def create_event_hash(provider_type)
      @create_event_hash ||= OmniEvent::EventHash.new(provider: provider_type, data: data)
    end

    def update_event_hash(provider_type)
      @update_event_hash ||=
        OmniEvent::EventHash.new(
          provider: provider_type,
          data: data.compact,
          metadata: metadata.compact,
        )
    end

    def destroy_event_hash(provider_type)
      @update_event_hash ||=
        OmniEvent::EventHash.new(provider: provider_type, metadata: metadata.compact)
    end
  end
end
