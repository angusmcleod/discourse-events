# frozen_string_literal: true

Fabricator(:discourse_events_log, from: "DiscourseEvents::Log") do
  level { "info" }
  message { sequence(:message) { |i| "Log #{i}" } }
end
