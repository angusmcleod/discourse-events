# frozen_string_literal: true

module DiscourseEvents
  class EventTopicController < AdminController
    before_action :find_event
    before_action :find_topic, only: [:connect]

    def connect
      topic_opts = {}

      user = current_user
      if params[:username]
        user = User.find_by(username: params[:username])
        raise Discourse::InvalidParameters.new(:username) if user.blank?
      end

      category_id = params[:category_id]
      category = nil
      if category_id
        category = Category.find_by(id: category_id)
        raise Discourse::InvalidParameters.new(:category_id) if category.blank?
        topic_opts[:category] = category_id
      end

      client = params[:client]
      raise Discourse::InvalidParameters.new(:client) if Source.available_clients.exclude?(client)

      if !@topic && client == "discourse_events"
        raise Discourse::InvalidParameters.new(:category_id) unless category&.events_enabled
      end

      syncer = SyncManager.new_client(client, user)
      connected_topic = nil
      ActiveRecord::Base.transaction do
        if @topic
          event_topic = EventTopic.create!(event_id: @event.id, topic_id: @topic.id)
          connected_topic = syncer.connect_topic(@topic, @event)
        else
          connected_topic = syncer.create_topic(@event, topic_opts)
        end
        raise ActiveRecord::Rollback unless connected_topic
      end

      if connected_topic.present?
        render json: success_json
      else
        render json: failed_json
      end
    end

    def update
      event_topic = @event.event_topics.first

      syncer = SyncManager.new_client(event_topic.client, event_topic.topic.first_post.user)
      updated_topic = syncer.update_topic(event_topic.topic, @event)

      if updated_topic.present?
        render json: success_json
      else
        render json: failed_json
      end
    end

    protected

    def find_event
      event_id = params[:event_id]
      @event = Event.find_by(id: event_id)
      raise Discourse::InvalidParameters.new(:event_id) unless @event
    end

    def find_topic
      topic_id = params[:topic_id]
      @topic = nil
      if topic_id
        @topic = Topic.find_by(id: topic_id)
        raise Discourse::InvalidParameters.new(:topic_id) unless @topic
      elsif action_name.to_sym == :update
        raise Discourse::InvalidParameters.new(:topic_id)
      end
    end
  end
end
