# frozen_string_literal: true

module DiscourseEvents
  class ConnectionController < AdminController
    include DiscourseEvents::Filters

    def index
      connections = Connection.includes(:user)

      render_json_dump(
        connections: serialize_data(connections, ConnectionSerializer, root: false),
        sources: serialize_data(Source.all, SourceSerializer, root: false),
      )
    end

    def create
      create_or_update

      if @errors.blank?
        render_serialized(@model, ConnectionSerializer, root: "connection")
      else
        render json: failed_json.merge(errors: @errors.map(&:full_messages).flatten), status: 400
      end
    end

    def update
      create_or_update

      if @errors.blank?
        render_serialized(@model, ConnectionSerializer, root: "connection")
      else
        render json: failed_json.merge(errors: @errors.map(&:full_messages).flatten), status: 400
      end
    end

    def sync
      connection = Connection.find_by(id: params[:id])
      raise Discourse::InvalidParameters.new(:id) unless connection

      ::Jobs.enqueue(:discourse_events_sync_connection, connection_id: connection.id)

      render json: success_json
    end

    def destroy
      if Connection.destroy(params[:id])
        render json: success_json
      else
        render json: failed_json
      end
    end

    protected

    def connection_params
      result =
        params
          .require(:connection)
          .permit(
            :user_id,
            :category_id,
            :source_id,
            :client,
            :auto_sync,
            filters: %i[id query_column query_operator query_value],
          )
          .to_h

      if !result[:user_id] && params[:connection][:user].present?
        user = User.find_by(username: params.dig(:connection, :user, :username))
        result[:user_id] = user.id
      end

      unless subscription.supports_feature_value?(:connection, result[:client])
        raise Discourse::InvalidParameters, "client not included in subscription"
      end

      result
    end

    def create_or_update
      @errors = []
      opts = connection_params.slice(:user_id, :category_id, :source_id, :client, :auto_sync)

      ActiveRecord::Base.transaction do
        if action_name === "create"
          @model = Connection.create(opts)
        else
          @model = Connection.update(params[:id], opts)
        end

        if @model.errors.any?
          @errors << @model.errors
          raise ActiveRecord::Rollback
        end

        save_filters
      end
    end

    def valid_filters
      @valid_filters ||=
        begin
          (connection_params[:filters] || []).select do |filter|
            has_keys =
              %i[id query_column query_operator query_value].all? { |key| filter.key?(key) }
            has_values = filter.values.all?(&:present?)
            has_keys && has_values
          end
        end
    end
  end
end
