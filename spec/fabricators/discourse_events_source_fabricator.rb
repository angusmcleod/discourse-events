# frozen_string_literal: true

Fabricator(:discourse_events_source, from: "DiscourseEvents::Source") do
  name { sequence(:name) { |i| "source_#{i}" } }
  provider { Fabricate(:discourse_events_provider) }
  import_type { DiscourseEvents::Source.import_types[:import] }
end
