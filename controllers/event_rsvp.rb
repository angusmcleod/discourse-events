class CalendarEvents::RsvpController < ApplicationController
  attr_accessor :topic
  before_action :check_user_and_find_topic, only: [:add, :remove]
  before_action :check_if_rsvp_enabled

  def add
    prop = "event_#{rsvp_params[:type]}".freeze

    list = @topic.send(prop) || []

    if @topic.event_going_max && list.length >= @topic.event_going_max
      raise I18n.t('event_rsvp.errors.going_max')
    end

    list.push(rsvp_params[:username])

    @topic.custom_fields[prop] = list.join(',')

    if topic.save_custom_fields(true)
      push_update(topic, prop)
      update_reminders(rsvp_params[:username], 'added')

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
      update_reminders(rsvp_params[:username], 'removed')

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

  def update_reminders(username, type)
    opts = { topic_id: @topic.id }
    opts["#{type}_usernames".to_sym] = [username]
    Jobs.enqueue(:update_event_reminders, opts)
  end
end
