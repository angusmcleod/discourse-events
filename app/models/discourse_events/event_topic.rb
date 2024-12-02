# frozen_string_literal: true

module DiscourseEvents
  class EventTopic < ActiveRecord::Base
    self.table_name = "discourse_events_event_topics"

    belongs_to :event, foreign_key: "event_id", class_name: "DiscourseEvents::Event"
    belongs_to :topic
  end
end

# == Schema Information
#
# Table name: discourse_events_event_topics
#
#  id         :bigint           not null, primary key
#  event_id   :bigint
#  topic_id   :bigint
#  series_id  :string
#  client     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  discourse_events_event_topics_index               (event_id,topic_id) UNIQUE
#  index_discourse_events_event_topics_on_event_id   (event_id)
#  index_discourse_events_event_topics_on_series_id  (series_id)
#  index_discourse_events_event_topics_on_topic_id   (topic_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => discourse_events_events.id)
#
