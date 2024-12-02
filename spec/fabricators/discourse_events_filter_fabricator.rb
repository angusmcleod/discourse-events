# frozen_string_literal: true

Fabricator(:discourse_events_filter, from: "DiscourseEvents::Filter") do
  model { Fabricate(:discourse_events_source) }
  query_column { :name }
  query_operator { :like }
end
