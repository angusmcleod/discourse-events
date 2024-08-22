# frozen_string_literal: true

module DiscourseEvents
  PLUGIN_NAME ||= "discourse-events"

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
end
