# frozen_string_literal: true

module DiscourseEvents
  class EventController < AdminController
    PAGE_LIMIT = 30

    def index
      filter = params[:filter]
      if filter && %w[unconnected connected].exclude?(filter)
        raise Discourse::InvalidParameters.new(:filter)
      end

      order = params[:order]
      raise Discourse::InvalidParameters.new(:order) if order && %w[start_time name].exclude?(order)
      order ||= "start_time"

      direction = ActiveRecord::Type::Boolean.new.cast(params[:asc]) ? "ASC" : "DESC"
      page = params[:page].to_i
      offset = page * PAGE_LIMIT
      limit = PAGE_LIMIT

      filter_sql =
        if filter
          "WHERE ec.topic_id IS #{filter === "unconnected" ? "NULL" : "NOT NULL"}"
        else
          ""
        end
      events_sql = (<<~SQL)
        SELECT * FROM (#{Event.distinct_events_sql(filter_sql: filter_sql)}) AS distinct_events
        ORDER BY #{order} #{direction}
        OFFSET #{offset}
        LIMIT #{limit}
      SQL

      events = DB.query(events_sql)

      with_topics_sql = (<<~SQL)
        SELECT COUNT(id) FROM (#{Event.distinct_events_sql}) AS distinct_events
        WHERE cardinality(topic_ids) > 0
      SQL

      without_topics_sql = (<<~SQL)
        SELECT COUNT(id) FROM (#{Event.distinct_events_sql}) AS distinct_events
        WHERE cardinality(topic_ids) = 0
      SQL

      with_topics_query = DB.query(with_topics_sql)
      without_topics_query = DB.query(without_topics_sql)

      render_json_dump(
        page: page,
        filter: filter,
        order: order,
        with_topics_count: with_topics_query.first.count,
        without_topics_count: without_topics_query.first.count,
        events: serialize_data(events, EventSerializer, root: false),
        providers: serialize_data(Provider.all, ProviderSerializer, root: false),
      )
    end

    def connect
      event_id = params[:event_id]
      event = Event.find_by(id: event_id)
      raise Discourse::InvalidParameters.new(:event_id) unless event

      topic_id = params[:topic_id]
      topic = Topic.find_by(id: topic_id)
      raise Discourse::InvalidParameters.new(:topic_id) unless topic

      client = params[:client]
      unless Connection.available_clients.include?(client)
        raise Discourse::InvalidParameters.new(:client)
      end

      topic_with_event = nil
      ActiveRecord::Base.transaction do
        event_connection =
          EventConnection.create!(event_id: event.id, topic_id: topic.id, client: client)
        syncer = "DiscourseEvents::#{client.camelize}Syncer".constantize.new(current_user)
        topic_with_event = syncer.connect_event_to_topic(topic, event)
        raise ActiveRecord::Rollback unless topic_with_event
      end

      if topic_with_event.present?
        render json: success_json
      else
        render json: failed_json
      end
    end

    def destroy
      event_ids = params[:event_ids]
      target = params[:target]
      result = { destroyed_event_ids: [], destroyed_topics_event_ids: [] }

      ActiveRecord::Base.transaction do
        events = Event.where(id: event_ids)

        if target === "events_and_topics" || target === "topics_only"
          event_connections = {}

          events
            .includes(:event_connections)
            .each do |event|
              event.event_connections.each do |ec|
                destroyer = PostDestroyer.new(current_user, ec.topic.first_post)
                destroyer.destroy
                event_connections[ec.id] ||= ec
              end

              result[:destroyed_topics_event_ids] << event.id
            end

          DiscourseEvents::EventConnection.where(id: event_connections.keys).delete_all
        end

        if target === "events_only" || target === "events_and_topics"
          destroyed_events = events.destroy_all
          result[:destroyed_event_ids] += destroyed_events.map(&:id)
        end
      end

      if result[:destroyed_event_ids].present? || result[:destroyed_topics_event_ids].present?
        render json: success_json.merge(result)
      else
        render json: failed_json
      end
    end
  end
end
