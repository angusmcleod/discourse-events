# frozen_string_literal: true

module DiscourseEvents
  PLUGIN_NAME = "discourse-events"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseEvents
  end

  USER_API_KEY_SCOPE = "calendar_events"

  def self.base_url
    if Rails.env.development? && ENV["RAILS_DEVELOPMENT_HOSTS"]
      "https://#{ENV["RAILS_DEVELOPMENT_HOSTS"].split(",").first}"
    else
      Discourse.base_url
    end
  end

  def self.discourse_post_event_installed?
    defined?(DiscoursePostEvent) == "constant" && DiscoursePostEvent.class == Module
  end

  def self.discourse_post_event_ready?
    discourse_post_event_installed? && SiteSetting.calendar_enabled &&
      SiteSetting.discourse_post_event_enabled
  end

  class NotSubscribed < StandardError
  end
end
