# frozen_string_literal: true

Fabricator(:discourse_events_event, from: "DiscourseEvents::Event") do
  uid { sequence(:uid) { |i| "#{i}1870a940bbcbb46f06880ed338d58a07" } }
  start_time { 2.days.from_now }
  end_time { 2.days.from_now + 1.hour }
  name { sequence(:name) { |i| "Event #{i}" } }
  description { sequence(:description) { |i| "Event description #{i}" } }
  taxonomy { "cats" }
  status { "published" }
  url { sequence(:url) { |i| "my/#{i}/url" } }
  source { Fabricate(:discourse_events_source) }
end
