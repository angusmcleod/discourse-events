class CalendarEvents::ApiKeysController < ApplicationController

  APPLICATION_NAME = 'discourse-events'
  SCOPES = [CalendarEvents::USER_API_KEY_SCOPE]

  before_action :ensure_logged_in

=begin
  As soon as a new client_id is passed for the same API key, the key record
  will be updated to contain the new client_id automatically.
  See Auth::DefaultCurrentUserProvider#lookup_user_api_user_and_update_key

  This means that rate limits could be exceeded in some cases.
  TODO: Instead we should allow a unique key to be created for each client.
=end
  def index
    key = find_or_create!
    render json: [{
      key: key.key,
      client_id: key.client_id,
    }]
  end

  private

  def find_or_create!
    # We use UserApiKey instead of ApiKey so that the surface area of
    # a leaked key is as small as possible (using UserApiKey.scopes).
    key = UserApiKey.find_by attributes
    return key if key
    UserApiKey.create! attributes.reverse_merge(
      key: SecureRandom.hex(32),
      scopes: SCOPES,
      # client_id has a unique constraint
      client_id: SecureRandom.uuid,
    )
  end

  def attributes
    {
      application_name: APPLICATION_NAME,
      user_id: current_user.id,
    }
  end

end
