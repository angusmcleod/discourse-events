# frozen_string_literal: true
class DiscourseEvents::ApiKeysController < ApplicationController
  APPLICATION_NAME = "discourse-events"

  requires_plugin DiscourseEvents::PLUGIN_NAME

  before_action :ensure_logged_in

  def index
    client = nil
    key = nil
    ActiveRecord::Base.transaction do
      client = UserApiKeyClient.find_by(application_name: APPLICATION_NAME)
      client =
        UserApiKeyClient.create!(
          application_name: APPLICATION_NAME,
          client_id: SecureRandom.uuid,
        ) if client.blank?
      key =
        UserApiKey.create!(
          user_api_key_client_id: client.id,
          user_id: current_user.id,
          scopes: [
            UserApiKeyScope.new(name: "#{APPLICATION_NAME}:#{DiscourseEvents::USER_API_KEY_SCOPE}"),
          ],
        )
    end

    render json: [{ key: key.key, client_id: client.client_id }]
  end
end
