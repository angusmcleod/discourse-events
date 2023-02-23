# frozen_string_literal: true

module DiscourseEvents
  class ProviderSerializer < ApplicationSerializer
    attributes :id,
               :name,
               :provider_type,
               :url,
               :username,
               :password,
               :token,
               :client_id,
               :client_secret,
               :authenticated

    def authenticated
      object.authenticated?
    end
  end
end
