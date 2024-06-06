# frozen_string_literal: true

Fabricator(:discourse_events_connection, from: "DiscourseEvents::Connection") do
  client { "events" }
  source { Fabricate(:discourse_events_source) }
  user { Fabricate(:user) }
  category { Fabricate(:category) }
end
