# frozen_string_literal: true

module DiscourseEvents
  class EventController < AdminController
    PAGE_LIMIT = 30

    def index
      page = params[:page].to_i
      order = params[:order].present? ? params[:order] : "start_time"
      filter = params[:filter]
      direction = ActiveRecord::Type::Boolean.new.cast(params[:asc]) ? "ASC" : "DESC"
      offset = page * PAGE_LIMIT

      events = Event.includes(:sources, event_connections: [:topic]).references(:event_connections)

      if filter == "connected"
        events = events.where("discourse_events_event_connections.topic_id IS NOT NULL")
      elsif filter == "unconnected"
        events = events.where("discourse_events_event_connections.topic_id IS NULL")
      end

      events = events.order("#{order} #{direction}").offset(offset).limit(PAGE_LIMIT)

      render_json_dump(page: page, events: serialize_data(events, EventSerializer, root: false))
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
