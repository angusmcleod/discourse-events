# frozen_string_literal: true

module DiscourseEvents
  class Connection < ActiveRecord::Base
    self.table_name = "discourse_events_connections"

    CLIENTS ||= { discourse_events: "discourse-events", discourse_calendar: "discourse-calendar" }

    def self.client_names
      CLIENTS.keys.map(&:to_s)
    end

    has_many :event_connections,
             foreign_key: "connection_id",
             class_name: "DiscourseEvents::EventConnection",
             dependent: :destroy
    has_many :events, through: :event_connections, source: :event
    has_many :filters,
             -> { where(model_type: "DiscourseEvents::Connection") },
             foreign_key: "model_id",
             class_name: "DiscourseEvents::Filter",
             dependent: :destroy

    belongs_to :user
    belongs_to :category
    belongs_to :source, foreign_key: "source_id", class_name: "DiscourseEvents::Source"

    validates :client,
              inclusion: {
                in: Connection.client_names,
                message: "%{value} is not a valid connection client",
              }
    validates :user, presence: true
    validates :category, presence: true
    validates :source, presence: true

    def self.available_clients
      CLIENTS.select { |client, plugin| plugins.include?(plugin) }.keys.map(&:to_s)
    end

    def self.plugins
      Discourse.plugins.map(&:name)
    end
  end
end

# == Schema Information
#
# Table name: discourse_events_connections
#
#  id          :bigint           not null, primary key
#  user_id     :bigint
#  source_id   :bigint           not null
#  category_id :bigint
#  client      :string           default("discourse_events")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  auto_sync   :boolean
#
# Indexes
#
#  events_source_category_connection_index            (source_id,category_id) UNIQUE
#  index_discourse_events_connections_on_category_id  (category_id)
#  index_discourse_events_connections_on_source_id    (source_id)
#  index_discourse_events_connections_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (source_id => discourse_events_sources.id)
#
