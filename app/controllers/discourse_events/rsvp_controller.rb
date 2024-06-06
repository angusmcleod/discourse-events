# frozen_string_literal: true
class DiscourseEvents::RsvpController < ApplicationController
  attr_accessor :topic
  before_action :check_user_and_find_topic, only: %i[add remove]
  before_action :check_if_rsvp_enabled, except: [:users]

  requires_plugin DiscourseEvents::PLUGIN_NAME

  def add
    prop = Hash.new
    prop[:key] = "event_#{rsvp_params[:type]}".freeze

    list = @topic.send(prop[:key]) || []

    if @topic.event_going_max && list.length >= @topic.event_going_max
      raise I18n.t("event_rsvp.errors.going_max")
    end

    list.push(User.find_by(username: rsvp_params[:usernames].first).id)

    @topic.custom_fields[prop[:key]] = list
    prop[:value] = User.find(list).pluck(:username)

    if topic.save_custom_fields(true)
      push_update(topic, prop)

      render json: success_json
    else
      render json: failed_json
    end
  end

  def remove
    prop = Hash.new
    prop[:key] = "event_#{rsvp_params[:type]}".freeze

    list = @topic.send(prop[:key]) || []
    list.delete(User.find_by(username: rsvp_params[:usernames].first).id)

    @topic.custom_fields[prop[:key]] = list
    prop[:value] = User.find(list).pluck(:username)

    if topic.save_custom_fields(true)
      push_update(topic, prop)

      render json: success_json
    else
      render json: failed_json
    end
  end

  def users
    if rsvp_params[:usernames].present?
      begin
        users = User.where(username: rsvp_params[:usernames])
        render_json_dump(success_json.merge(users: serialize_data(users, BasicUserSerializer)))
      rescue StandardError
        render_json_dump "[]"
      end
    else
      render_json_dump "[]"
    end
  end

  private

  def rsvp_params
    params.permit(:topic_id, :type, usernames: [])
  end

  def check_user_and_find_topic
    raise Discourse::InvalidAccess.new unless User.exists?(username: rsvp_params[:usernames].first)

    if topic = Topic.find_by(id: rsvp_params[:topic_id])
      @topic = topic
    else
      raise Discourse::NotFound.new
    end
  end

  def check_if_rsvp_enabled
    unless SiteSetting.events_rsvp && @topic.event_rsvp
      raise I18n.t("event_rsvp.errors.not_enabled")
    end
  end

  def push_update(topic, prop)
    channel = "/calendar-events/#{topic.id}"

    msg = { current_user_id: current_user.id, updated_at: Time.now, type: "rsvp" }

    msg[prop[:key]] = prop[:value]

    MessageBus.publish(channel, msg)
  end
end
