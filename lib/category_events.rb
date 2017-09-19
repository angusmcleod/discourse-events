# frozen_string_literal: true

module ::CategoryEvents
  class Engine < ::Rails::Engine
    engine_name 'category_events'
    isolate_namespace CategoryEvents
  end
end

CategoryEvents::Engine.routes.draw do
  get 'l/:category_id' => 'event#category_list'
end

Discourse::Application.routes.append do
  mount ::CategoryEvents::Engine, at: 'events'
end

class CategoryEvents::EventController < ApplicationController
  def category_list
    params.require(:category_id)
    params.permit(:period)

    opts = { category_id: params[:category_id] }

    opts[:period] = params[:period] if params.include?(:period)

    events = CategoryEventsHelper.events_for_category(opts)

    render_serialized(events, CategoryEvents::EventSerializer)
  end
end

class CategoryEvents::EventSerializer < ApplicationSerializer
  attributes :title, :start, :end, :url

  def start
    Time.at(object.topic.custom_fields['event_start']).iso8601
  end

  def end
    Time.at(object.topic.custom_fields['event_end']).iso8601
  end
end

module CategoryEventsHelper
  class << self
    def events_for_category(opts)
      topics = Topic.joins("INNER JOIN topic_custom_fields
                            ON topic_custom_fields.topic_id = topics.id
                            AND (topic_custom_fields.name = 'event_start'
                                OR topic_custom_fields.name = 'event_end')")
      topics = topics.where(category_id: opts[:category_id])
      events = []

      topics.each do |t|
        event_start = t.custom_fields['event_start']
        event_end = t.custom_fields['event_end']

        within_period = case opts[:period]
                        when 'upcoming'
                          event_start >= Time.now.iso8601
                        when 'past'
                          event_end < Time.now.iso8601
                        else
                          true
        end

        events.push(t) if within_period

        events
      end
    end
  end
end
