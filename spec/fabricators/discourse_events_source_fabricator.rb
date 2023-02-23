# frozen_string_literal: true

Fabricator(:discourse_events_source, from: "DiscourseEvents::Source") do
  name { sequence(:name) { |i| "source_#{i}" } }
  provider { Fabricate(:discourse_events_provider) }
  taxonomy { 'cats' }
  status { 'published' }
end
