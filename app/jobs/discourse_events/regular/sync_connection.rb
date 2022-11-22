# frozen_string_literal: true

module ::Jobs
  class DiscourseEventsSyncConnection < ::Jobs::Base
    def execute(args)
      ::DiscourseEvents::SyncManager.sync_connection(args[:connection_id])
    end
  end
end
