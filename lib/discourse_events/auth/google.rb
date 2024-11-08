# frozen_string_literal: true

module DiscourseEvents
  module Auth
    class Google < Base
      def base_url
        "https://oauth2.googleapis.com/token"
      end

      def authorization_url(state)
        uri = URI.parse("https://accounts.google.com/o/oauth2/v2/auth")
        uri.query =
          URI.encode_www_form(
            scope: "https://www.googleapis.com/auth/calendar",
            access_type: "offline",
            response_type: "code",
            state: state,
            redirect_uri: provider.redirect_uri,
            client_id: provider.client_id,
          )
        uri.to_s
      end

      def request_token(code)
        body = {
          client_id: provider.client_id,
          client_secret: provider.client_secret,
          grant_type: "authorization_code",
          redirect_uri: provider.redirect_uri,
          code: code,
        }
        perform_request(body)
      end

      def refresh_token!
        body = {
          client_id: provider.client_id,
          client_secret: provider.client_secret,
          grant_type: "refresh_token",
          refresh_token: provider.refresh_token,
        }
        perform_request(body)
      end

      protected

      def perform_request(body)
        response =
          Excon.post(
            "https://oauth2.googleapis.com/token",
            headers: {
              "Content-Type" => "application/x-www-form-urlencoded",
            },
            body: URI.encode_www_form(body),
          )

        if response.status != 200
          log(
            :error,
            "Failed to retrieve access token for #{provider.name}: #{parse_body(response)}",
          )
          return false
        end

        data = parse_body(response)
        return false unless data

        log(:info, "Google auth succeeded: #{data}") if SiteSetting.events_verbose_auth_logs

        provider.token = data["access_token"]
        provider.token_expires_at = Time.now + data["expires_in"].seconds
        provider.refresh_token = data["refresh_token"] if data["refresh_token"].present?

        if provider.save!
          ::Jobs.cancel_scheduled_job(:discourse_events_refresh_token, provider_id: provider.id)
          refresh_at = provider.reload.token_expires_at.to_time - 10.minutes
          ::Jobs.enqueue_at(refresh_at, :discourse_events_refresh_token, provider_id: provider.id)
        else
          log(:error, "Failed to save access token for #{provider.name}")
          false
        end
      end

      def parse_body(response)
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        message = response.body&.to_s&.[](0..100)
        log(:error, "Failed to parse access token response for #{provider.name}: #{message}")
        nil
      end
    end
  end
end
