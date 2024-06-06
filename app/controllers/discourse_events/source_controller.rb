# frozen_string_literal: true

module DiscourseEvents
  class SourceController < AdminController
    def index
      render_json_dump(
        sources: serialize_data(Source.all, SourceSerializer, root: false),
        providers: serialize_data(Provider.all, ProviderSerializer, root: false),
      )
    end

    def create
      source = Source.create(source_params)

      if source.errors.blank?
        render_serialized(source, SourceSerializer, root: "source")
      else
        render json: failed_json.merge(errors: source.errors.full_messages), status: 400
      end
    end

    def update
      source = Source.update(params[:id], source_params)

      if source.errors.blank?
        render_serialized(source, SourceSerializer, root: "source")
      else
        render json: failed_json.merge(errors: source.errors.full_messages), status: 400
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
      params.require(:source).permit(
        :name,
        :provider_id,
        :from_time,
        :to_time,
        :status,
        :taxonomy,
        source_options: {},
      )
    end
  end
end
