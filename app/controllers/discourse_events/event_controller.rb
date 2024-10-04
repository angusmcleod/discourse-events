# frozen_string_literal: true

module DiscourseEvents
  class EventController < AdminController
    PAGE_LIMIT = 30

    def index
      order = params[:order]
      raise Discourse::InvalidParameters.new(:order) if order && %w[start_time name].exclude?(order)
      order ||= "start_time"

      direction = ActiveRecord::Type::Boolean.new.cast(params[:asc]) ? "ASC" : "DESC"
      page = params[:page].to_i
      offset = page * PAGE_LIMIT
      limit = PAGE_LIMIT

      events =
        DB.query(events_sql(order: order, direction: direction, offset: offset, limit: limit))

      with_topics_sql = (<<~SQL)
        SELECT COUNT(id) FROM (#{Event.list_sql}) AS events
        WHERE cardinality(topic_ids) > 0
      SQL

      without_topics_sql = (<<~SQL)
        SELECT COUNT(id) FROM (#{Event.list_sql}) AS events
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

    def all
      events = DB.query(events_sql)
      render json: { event_ids: events.map(&:id) }.as_json
    end

    def connect
      event_id = params[:event_id]
      event = Event.find_by(id: event_id)
      raise Discourse::InvalidParameters.new(:event_id) unless event

      topic_id = params[:topic_id]
      topic = nil
      if topic_id
        topic = Topic.find_by(id: topic_id)
        raise Discourse::InvalidParameters.new(:topic_id) unless topic
      end

      client = params[:client]
      unless Source.available_clients.include?(client)
        raise Discourse::InvalidParameters.new(:client)
      end

      syncer = SyncManager.new_client(client, current_user)
      ActiveRecord::Base.transaction do
        if topic
          event_topic = EventTopic.create!(event_id: event.id, topic_id: topic.id)
          topic_id = syncer.connect_topic(topic, event)
        else
          topic_id = syncer.create_topic(event)
        end
        raise ActiveRecord::Rollback unless topic_id
      end

      if topic_id.present?
        render json: success_json
      else
        render json: failed_json
      end
    end

    def destroy
      event_ids = params[:event_ids]
      target = params[:target]

      result = EventDestroyer.perform(user: current_user, event_ids: event_ids, target: target)

      if result[:destroyed_event_ids].present? || result[:destroyed_topics_event_ids].present?
        render json: success_json.merge(result)
      else
        render json: failed_json
      end
    end

    protected

    def filter
      @filter ||=
        begin
          result = params[:filter]
          if result && %w[unconnected connected].exclude?(result)
            raise Discourse::InvalidParameters.new(:filter)
          end
          result
        end
    end

    def filter_sql
      @filter_sql ||=
        begin
          if filter
            "WHERE et.topic_id IS #{filter === "unconnected" ? "NULL" : "NOT NULL"}"
          else
            ""
          end
        end
    end

    def events_sql(order: nil, direction: nil, offset: nil, limit: nil)
      sql = (<<~SQL)
        SELECT * FROM (#{Event.list_sql(filter_sql: filter_sql)}) AS events
      SQL

      sql << (<<~SQL) if !order.nil? && !direction.nil?
          ORDER BY #{order} #{direction}
        SQL

      sql << (<<~SQL) if !offset.nil? && !limit.nil?
          OFFSET #{offset}
          LIMIT #{limit}
        SQL

      sql
    end
  end
end
