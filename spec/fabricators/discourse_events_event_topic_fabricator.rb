# frozen_string_literal: true

Fabricator(:discourse_events_event_topic, from: "DiscourseEvents::EventTopic") do
  event { Fabricate(:discourse_events_event) }
  client { "discourse_events" }
end
