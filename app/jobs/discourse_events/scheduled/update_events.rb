# frozen_string_literal: true

module ::Jobs
  class DiscourseEventsUpateEvents < ::Jobs::Scheduled
    every SiteSetting.events_update_automatically_period_mins.minutes

    def execute(args)
      if should_update?
        DiscourseEvents::ImportManager.import_all_sources
        DiscourseEvents::SyncManager.sync_all_connections
      end
    end

    def should_update?
      return false if Rails.env.development? && ENV["UPDATE_EVENTS"].nil?
      SiteSetting.events_update_automatically?
    end
  end
end
