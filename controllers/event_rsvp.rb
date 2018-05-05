class CalendarEvents::RsvpController < ApplicationController
  attr_accessor :topic
  before_action :check_user_and_find_topic, only: [:add, :remove]

  def add
    prop = "event_#{rsvp_params[:type]}".freeze

    list = @topic.send(prop) || []

    list.push(rsvp_params[:username])

    @topic.custom_fields[prop] = list.join(',')

    if topic.save_custom_fields(true)
      push_update(topic, prop)

      render json: success_json
    else
      render json: failed_json
    end
  end

  def remove
    prop = "event_#{rsvp_params[:type]}".freeze

    list = @topic.send(prop) || []

    list.delete(rsvp_params[:username])

    @topic.custom_fields[prop] = list.join(',')

    if topic.save_custom_fields(true)
      push_update(topic, prop)

      render json: success_json
    else
      render json: failed_json
    end
  end

  private

  def rsvp_params
    params.permit(:topic_id, :type, :username)
  end

  def check_user_and_find_topic
    unless User.exists?(username: rsvp_params[:username])
      raise Discourse::InvalidAccess.new
    end

    if topic = Topic.find_by(id: rsvp_params[:topic_id])
      @topic = topic
    else
      raise Discourse::NotFound.new
    end
  end

  def push_update(topic, prop)
    channel = "/calendar-events/#{topic.id}"

    msg = {
      current_user_id: current_user.id,
      updated_at: Time.now,
      type: "rsvp"
    }

    msg[prop.to_sym] = topic.send(prop)

    MessageBus.publish(channel, msg)
  end
end
