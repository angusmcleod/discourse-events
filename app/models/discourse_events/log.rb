# frozen_string_literal: true

module DiscourseEvents
  class Log < ActiveRecord::Base
    self.table_name = "discourse_events_logs"

    enum :level, %i[info error]
    enum :context, %i[import sync auth publish]

    validates :message, presence: true
    validates :level, presence: true
  end
end

# == Schema Information
#
# Table name: discourse_events_logs
#
#  id         :bigint           not null, primary key
#  level      :integer
#  context    :integer
#  message    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
