# frozen_string_literal: true

module ::Jobs
  class DiscourseEventsSyncConnection < ::Jobs::Base
    def execute(args)
      ::DiscourseEvents::SyncManager.sync_connection_by_id(args[:connection_id])
    end
  end
end
