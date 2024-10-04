# frozen_string_literal: true

Fabricator(:discourse_events_event_registration, from: "DiscourseEvents::EventRegistration") do
  event { Fabricate(:discourse_events_event) }
  email { sequence(:email) { |i| "angus#{i}@email.com" } }
end
