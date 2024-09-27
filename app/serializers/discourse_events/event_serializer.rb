# frozen_string_literal: true

module DiscourseEvents
  class EventSerializer < BasicEventSerializer
    attributes :series_id, :topic_ids, :source_id, :provider_id
  end
end
