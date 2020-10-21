class CalendarEvents::ApiKeysController < ApplicationController

  APPLICATION_NAME = 'discourse-events'
  SCOPES = [UserApiKeyScope.new(name: CalendarEvents::USER_API_KEY_SCOPE)]

  before_action :ensure_logged_in

=begin
  As soon as a new client_id is passed for the same API key, the key record
  will be updated to contain the new client_id automatically.
  See Auth::DefaultCurrentUserProvider#lookup_user_api_user_and_update_key

  This means that rate limits could be exceeded in some cases.
  TODO: Instead we should allow a unique key to be created for each client.
=end
  def index
    key = UserApiKey.create! attributes.reverse_merge(
      scopes: SCOPES,
      # client_id has a unique constraint
      client_id: SecureRandom.uuid,
    )

    render json: [{
      key: key.key,
      client_id: key.client_id,
    }]
  end

  private

  def attributes
    {
      application_name: APPLICATION_NAME,
      user_id: current_user.id,
      revoked_at: nil
    }
  end

end
