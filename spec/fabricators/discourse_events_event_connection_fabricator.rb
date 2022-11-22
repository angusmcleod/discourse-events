# frozen_string_literal: true

Fabricator(:discourse_events_event_connection, from: "DiscourseEvents::EventConnection") do
  event { Fabricate(:discourse_events_event) }
  connection { Fabricate(:discourse_events_connection) }
  client { 'events' }
end
