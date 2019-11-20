class CalendarEvents::RsvpController < ApplicationController
  attr_accessor :topic
  before_action :check_user_and_find_topic, only: [:add, :remove]
  before_action :check_if_rsvp_enabled, except: [:get_users]

  def add
    prop = "event_#{rsvp_params[:type]}".freeze

    list = @topic.send(prop) || []

    if @topic.event_going_max && list.length >= @topic.event_going_max
      raise I18n.t('event_rsvp.errors.going_max')
    end

    list.push(rsvp_params[:user_id].to_i)

    @topic.custom_fields[prop] = list.to_json

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

    list.delete(rsvp_params[:user_id].to_i)

    @topic.custom_fields[prop] = list.to_json

    if topic.save_custom_fields(true)
      push_update(topic, prop)

      render json: success_json
    else
      render json: failed_json
    end
  end

  def users
    begin
      users = User.find(rsvp_params[:user_ids])
      render_json_dump(success_json.merge(users: serialize_data(users, BasicUserSerializer)))
    rescue
      render_json_dump "[]"
    end
  end

  private

  def rsvp_params
    params.permit(:topic_id, :type, :user_id, :user_ids =>[])
  end

  def check_user_and_find_topic
    unless User.exists?(id: rsvp_params[:user_id])
      raise Discourse::InvalidAccess.new
    end

    if topic = Topic.find_by(id: rsvp_params[:topic_id])
      @topic = topic
    else
      raise Discourse::NotFound.new
    end
  end

  def check_if_rsvp_enabled
    unless SiteSetting.events_rsvp && @topic.event_rsvp
      raise I18n.t('event_rsvp.errors.not_enabled')
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
