# frozen_string_literal: true

module DiscourseEvents
  class Provider < ActiveRecord::Base
    self.table_name = "discourse_events_providers"

    NO_AUTH ||= %w[developer icalendar]
    TOKEN ||= %w[eventbrite humanitix eventzilla]
    OAUTH2 ||= %w[meetup outlook google]
    TYPES = NO_AUTH + TOKEN + OAUTH2

    has_many :sources,
             foreign_key: "provider_id",
             class_name: "DiscourseEvents::Source",
             dependent: :destroy

    validates :name,
              uniqueness: true,
              format: {
                with: /\A[a-z0-9\_]+\Z/i,
                message: "%{value} is not a valid name",
              }
    validates :provider_type,
              inclusion: {
                in: TYPES,
                message: "%{value} is not a valid provider type",
              }

    before_create { self.name = self.provider_type unless self.name.present? }

    def options
      { token: self.token } if (TOKEN + OAUTH2).include?(self.provider_type)
    end

    def valid_token?
      case
      when no_auth_type?
        false
      when token_type?
        token.present?
      when oauth2_type?
        token.present? && (!token_expires_at || !token_expires_at.past?)
      else
        false
      end
    end

    def no_auth_type?
      NO_AUTH.include?(self.provider_type)
    end

    def token_type?
      TOKEN.include?(self.provider_type)
    end

    def oauth2_type?
      OAUTH2.include?(self.provider_type)
    end

    def authenticated?
      case
      when no_auth_type?
        true
      when token_type?, oauth2_type?
        valid_token?
      else
        false
      end
    end

    def can_authenticate?
      case
      when no_auth_type?
        false
      when token_type?
        false
      when oauth2_type?
        client_id && client_secret
      else
        false
      end
    end

    def authorization_url(state)
      return nil unless oauth2_type?
      auth.authorization_url(state)
    end

    def redirect_uri
      return nil unless oauth2_type?
      "#{DiscourseEvents.base_url}/admin/plugins/events/provider/redirect"
    end

    def request_token(code)
      auth.request_token(code)
    end

    def auth
      @auth ||=
        begin
          klass = "DiscourseEvents::Auth::#{self.provider_type.camelize}"
          return nil unless Module.const_get(klass)
          klass.constantize.new(self.id)
        end
    end
  end
end

# == Schema Information
#
# Table name: discourse_events_providers
#
#  id               :bigint           not null, primary key
#  name             :string           not null
#  provider_type    :string           not null
#  url              :string
#  username         :string
#  password         :string
#  token            :string
#  token_expires_at :datetime
#  client_id        :string
#  client_secret    :string
#  refresh_token    :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_discourse_events_providers_on_name  (name) UNIQUE
#
