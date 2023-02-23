# frozen_string_literal: true

module ::Jobs
  class DiscourseEventsRefreshToken < ::Jobs::Base
    def execute(args)
      provider = ::DiscourseEvents::Provider.find_by(id: args[:provider_id])
      return unless provider&.oauth2_type?

      provider.auth.refresh_token!
    end
  end
end
