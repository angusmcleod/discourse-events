# frozen_string_literal: true

module DiscourseEvents
  class SourceController < AdminController
    include DiscourseEvents::Filters

    def index
      render_json_dump(
        sources: serialize_data(Source.all, SourceSerializer, root: false),
        providers: serialize_data(Provider.all, ProviderSerializer, root: false),
        source_options: source_options,
        import_periods: import_periods,
      )
    end

    def create
      @errors = []

      ActiveRecord::Base.transaction do
        @model =
          Source.create(
            source_params.slice(
              :provider_id,
              :source_options,
              :import_period,
              :import_type,
              :topic_sync,
              :category_id,
              :user_id,
              :client,
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
              :provider_id,
              :source_options,
              :import_period,
              :import_type,
              :topic_sync,
              :category_id,
              :user_id,
              :client,
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

      ::Jobs.enqueue(:discourse_events_import_events, source_id: source.id)

      render json: success_json
    end

    def topics
      source = Source.find_by(id: params[:id])
      raise Discourse::InvalidParameters.new(:id) unless source

      ::Jobs.enqueue(:discourse_events_create_topics, source_id: source.id)

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
                :provider_id,
                :import_period,
                :import_type,
                :topic_sync,
                :category_id,
                :user_id,
                :client,
                source_options: {
                },
                filters: %i[id query_column query_operator query_value],
              )
              .to_h

          if result[:import_type].present? &&
               Source.import_types.keys.exclude?(result[:import_type])
            raise Discourse::InvalidParameters.new(:import_type)
          end

          if result[:topic_sync].present? && Source.topic_syncs.keys.exclude?(result[:topic_sync])
            raise Discourse::InvalidParameters.new(:topic_sync)
          end

          unless subscription.supports?(:source, :import_type, result[:import_type])
            raise Discourse::InvalidParameters,
                  "import #{result[:import_type]} is not supported by your subscription"
          end

          unless subscription.supports?(:source, :client, result[:client])
            raise Discourse::InvalidParameters,
                  "client #{result[:client]} is not supported by your subscription"
          end

          result
        end
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

    def source_options
      @source_options ||=
        begin
          DiscourseEvents::Source::SOURCE_OPTIONS.each_with_object(
            {},
          ) do |(provider, attrs), result|
            result[provider] = []
            attrs.each do |attr, val|
              number = val == /\d/
              result[provider] << {
                name: attr,
                type: number ? "number" : "text",
                default: number ? nil : "",
              }
            end
          end
        end
    end

    def import_periods
      @import_periods ||= { none: 0 }.merge(DiscourseEvents::Source::IMPORT_PERIODS)
    end
  end
end
