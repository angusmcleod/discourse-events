# frozen_string_literal: true

Fabricator(:discourse_events_connection_filter, from: "DiscourseEvents::ConnectionFilter") do
  connection { Fabricate(:discourse_events_connection) }
  query_column { :name }
end
