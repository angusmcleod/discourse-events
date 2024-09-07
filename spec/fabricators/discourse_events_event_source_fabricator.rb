# frozen_string_literal: true

Fabricator(:discourse_events_event_source, from: "DiscourseEvents::EventSource") do
  event { Fabricate(:discourse_events_event) }
  source { Fabricate(:discourse_events_source) }
  uid { sequence(:uid) { |i| "#{i}1870a940bbcbb46f06880ed338d58a07" } }
end
