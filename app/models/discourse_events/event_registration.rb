# frozen_string_literal: true

module DiscourseEvents
  class EventRegistration < ActiveRecord::Base
    self.table_name = "discourse_events_event_registrations"

    belongs_to :user
    belongs_to :event

    enum status: { confirmed: 0, declined: 1, tentative: 2, invited: 3 }
  end
end

# == Schema Information
#
# Table name: discourse_events_event_registrations
#
#  id         :bigint           not null, primary key
#  event_id   :bigint           not null
#  user_id    :bigint
#  email      :string           not null
#  uid        :string
#  name       :string
#  status     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  idx_events_event_registration_event_emails              (event_id,email) UNIQUE
#  index_discourse_events_event_registrations_on_event_id  (event_id)
#  index_discourse_events_event_registrations_on_user_id   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => discourse_events_events.id)
#
