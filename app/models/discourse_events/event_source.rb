# frozen_string_literal: true

module DiscourseEvents
  class EventSource < ActiveRecord::Base
    self.table_name = "discourse_events_event_sources"

    belongs_to :source, foreign_key: "source_id", class_name: "DiscourseEvents::Source"
    belongs_to :event, foreign_key: "event_id", class_name: "DiscourseEvents::Event"
  end
end

# == Schema Information
#
# Table name: discourse_events_event_sources
#
#  id         :bigint           not null, primary key
#  uid        :string           not null
#  source_id  :bigint
#  event_id   :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_discourse_events_event_sources_on_event_id   (event_id)
#  index_discourse_events_event_sources_on_source_id  (source_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => discourse_events_events.id)
#  fk_rails_...  (source_id => discourse_events_sources.id)
#
