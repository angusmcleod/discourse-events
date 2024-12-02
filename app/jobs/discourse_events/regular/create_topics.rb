# frozen_string_literal: true

module ::Jobs
  class DiscourseEventsCreateTopics < ::Jobs::Base
    def execute(args)
      ::DiscourseEvents::SyncManager.sync_source_by_id(args[:source_id])
    end
  end
end
