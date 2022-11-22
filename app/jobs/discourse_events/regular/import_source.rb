# frozen_string_literal: true

module ::Jobs
  class DiscourseEventsImportSource < ::Jobs::Base
    def execute(args)
      ::DiscourseEvents::ImportManager.import_source(args[:source_id])
    end
  end
end
