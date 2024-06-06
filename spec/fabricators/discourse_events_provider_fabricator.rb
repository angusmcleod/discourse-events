# frozen_string_literal: true

Fabricator(:discourse_events_provider, from: "DiscourseEvents::Provider") do
  name { sequence(:name) { |i| "provider_#{i}" } }
  provider_type { "developer" }
end
