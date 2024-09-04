# frozen_string_literal: true
module DiscourseEvents
  class Publisher::EventData
    attr_reader :start_time,
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
                :occurrence_id

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

    def create_event_hash
      @create_event_hash ||= OmniEvent::EventHash.new(data: data)
    end

    def update_event_hash
      @update_event_hash ||= OmniEvent::EventHash.new(data: data.compact)
    end

    def destroy_event_hash
      @update_event_hash ||= OmniEvent::EventHash.new(metadata: metadata)
    end
  end
end
