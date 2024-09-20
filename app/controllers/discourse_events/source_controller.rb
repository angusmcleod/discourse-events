# frozen_string_literal: true

module DiscourseEvents
  class SourceController < AdminController
    include DiscourseEvents::Filters

    def index
      render_json_dump(
        sources: serialize_data(Source.all, SourceSerializer, root: false),
        providers: serialize_data(Provider.all, ProviderSerializer, root: false),
      )
    end

    def create
      @errors = []

      ActiveRecord::Base.transaction do
        @model =
          Source.create(
            source_params.slice(
              :name,
              :provider_id,
              :status,
              :taxonomy,
              :source_options,
              :sync_type,
            ),
          )

        if @model.errors.any?
          @errors += @model.errors.full_messages
          raise ActiveRecord::Rollback
        end

        save_filters
      end

      if @errors.blank?
        render_serialized(@model, SourceSerializer, root: "source")
      else
        render json: failed_json.merge(errors: @errors), status: 400
      end
    end

    def update
      @errors = []

      ActiveRecord::Base.transaction do
        @model =
          Source.update(
            params[:id],
            source_params.slice(
              :name,
              :provider_id,
              :status,
              :taxonomy,
              :source_options,
              :sync_type,
            ),
          )

        if @model.errors.any?
          @errors += @model.errors.full_messages
          raise ActiveRecord::Rollback
        end

        save_filters
      end

      if @errors.blank?
        render_serialized(@model, SourceSerializer, root: "source")
      else
        render json: failed_json.merge(errors: @errors), status: 400
      end
    end

    def import
      source = Source.find_by(id: params[:id])
      raise Discourse::InvalidParameters.new(:id) unless source

      ::Jobs.enqueue(:discourse_events_import_source, source_id: source.id)

      render json: success_json
    end

    def destroy
      if Source.destroy(params[:id])
        render json: success_json
      else
        render json: failed_json
      end
    end

    protected

    def source_params
      @source_params ||=
        begin
          result =
            params
              .require(:source)
              .permit(
                :name,
                :provider_id,
                :status,
                :taxonomy,
                :sync_type,
                source_options: {
                },
                filters: %i[id query_column query_operator query_value],
              )
              .to_h

          unless subscription.supports_feature_value?(:source, result[:sync_type])
            raise Discourse::InvalidParameters, "sync_type not included in subscription"
          end

          result
        end
    end

    def subscription
      @subscription ||= SubscriptionManager.new
    end

    def valid_filters
      @valid_filters ||=
        begin
          (source_params[:filters] || []).select do |filter|
            has_keys =
              %i[id query_column query_operator query_value].all? { |key| filter.key?(key) }
            has_values = filter.values.all?(&:present?)
            has_keys && has_values
          end
        end
    end
  end
end
