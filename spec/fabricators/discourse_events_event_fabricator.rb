# frozen_string_literal: true

Fabricator(:discourse_events_event, from: "DiscourseEvents::Event") do
  start_time { 2.days.from_now }
  end_time { 2.days.from_now + 1.hour }
  name { sequence(:name) { |i| "Event #{i}" } }
  description { sequence(:description) { |i| "Event description #{i}" } }
  taxonomy { "cats" }
  status { "published" }
  url { sequence(:url) { |i| "my/#{i}/url" } }
end
