# frozen_string_literal: true

module DiscourseEvents
  class ConnectionController < AdminController
    def index
      connections = Connection.includes(:user)

      render_json_dump(
        connections: serialize_data(connections, ConnectionSerializer, root: false),
        sources: serialize_data(Source.all, SourceSerializer, root: false),
        clients: DiscourseEvents::Connection.available_clients
      )
    end

    def create
      create_or_update

      if @errors.blank?
        render_serialized(@connection, ConnectionSerializer, root: 'connection')
      else
        render json: failed_json.merge(errors: @errors.map(&:full_messages).flatten), status: 400
      end
    end

    def update
      create_or_update

      if @errors.blank?
        render_serialized(@connection, ConnectionSerializer, root: 'connection')
      else
        render json: failed_json.merge(errors: @errors.map(&:full_messages).flatten), status: 400
      end
    end

    def sync
      connection = Connection.find_by(id: params[:id])
      raise Discourse::InvalidParameters.new(:id) unless connection

      ::Jobs.enqueue(
        :discourse_events_sync_connection,
        connection_id: connection.id
      )

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
      result = params
        .require(:connection)
        .permit(
          :user_id,
          :category_id,
          :source_id,
          :client,
          filters: [:id, :query_column, :query_value]
        ).to_h

      if !result[:user_id] && params[:connection][:user].present?
        user = User.find_by(username: params.dig(:connection, :user, :username))
        result[:user_id] = user.id
      end

      result
    end

    def create_or_update
      @errors = []

      ActiveRecord::Base.transaction do
        if action_name === "create"
          @connection = Connection.create(connection_params.slice(:user_id, :category_id, :source_id, :client))
        else
          @connection = Connection.update(params[:id], connection_params.slice(:user_id, :category_id, :source_id, :client))
        end

        if @connection.errors.any?
          @errors << @connection.errors
          raise ActiveRecord::Rollback
        end

        if connection_params[:filters].present?
          valid_filters = connection_params[:filters].select do |filter|
            has_keys = %i[id query_column query_value].all? { |key| filter.key?(key) }
            has_values = filter.values.all?(&:present?)
            has_keys && has_values
          end

          saved_ids = []

          valid_filters.each do |f|
            params = f.slice(:query_column, :query_value)

            if f[:id] === "new"
              filter = @connection.filters.create(params)
            else
              filter = @connection.filters.update(f[:id].to_i, params)
            end

            if filter.errors.any?
              @errors << filter.errors
              raise ActiveRecord::Rollback
            end

            saved_ids << filter.id
          end

          @connection.filters.where.not(id: saved_ids).destroy_all
        end
      end
    end
  end
end
