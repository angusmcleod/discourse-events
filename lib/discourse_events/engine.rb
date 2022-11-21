# frozen_string_literal: true

module DiscourseEvents
  class Engine < ::Rails::Engine
    engine_name 'discourse_events'
    isolate_namespace DiscourseEvents
  end

  USER_API_KEY_SCOPE = 'calendar_events'
end
