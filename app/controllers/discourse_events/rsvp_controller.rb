# frozen_string_literal: true
class DiscourseEvents::RsvpController < ApplicationController
  before_action :find_user, only: %i[add remove]
  before_action :find_topic
  before_action :ensure_enabled
  before_action :set_user_ids

  SUPPORTED_TYPES = %w[going invited].freeze
  requires_plugin DiscourseEvents::PLUGIN_NAME

  def add
    if @topic.event_going_max && @user_ids.length >= @topic.event_going_max
      raise I18n.t("event_rsvp.errors.going_max")
    end

    @user_ids.push(@user.id)
    @topic.custom_fields["event_going"] = @user_ids

    if @topic.save_custom_fields(true)
      push_update
      render json: success_json
    else
      render json: failed_json
    end
  end

  def remove
    @user_ids.delete(@user.id)
    @topic.custom_fields["event_going"] = @user_ids

    if @topic.save_custom_fields(true)
      push_update
      render json: success_json
    else
      render json: failed_json
    end
  end

  def users
    render_serialized(User.where(id: @user_ids), BasicUserSerializer, root: "users")
  end

  private

  def rsvp_params
    params.permit(:topic_id, :type, :username)
  end

  def set_user_ids
    @type = params[:type]
    raise Discourse::InvalidParameters.new(:type) if SUPPORTED_TYPES.exclude?(@type)
    @user_ids = @topic.send("event_#{@type}")
  end

  def find_user
    @user = User.find_by(username: rsvp_params[:username])
    raise Discourse::NotFound.new(:username) if @user.blank?
  end

  def find_topic
    @topic = Topic.find_by(id: rsvp_params[:topic_id])
    raise Discourse::NotFound.new(:topic_id) if @topic.blank?
  end

  def ensure_enabled
    raise I18n.t("event_rsvp.errors.not_enabled") unless rsvp_enabled?
  end

  def rsvp_enabled?
    SiteSetting.events_rsvp && @topic && @topic.event_rsvp
  end

  def push_update
    msg = { updated_at: Time.now, type: "rsvp" }
    msg[@type.to_sym] = User.where(id: @user_ids).pluck(:username)
    MessageBus.publish("/discourse-events/#{@topic.id}", msg)
    DiscourseEvent.trigger(:discourse_events_rsvps_updated, @topic)
  end
end
