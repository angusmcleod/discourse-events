# frozen_string_literal: true

module DiscourseEvents
  module Auth
    class Base
      attr_reader :provider,
                  :logger

      def initialize(provider_id)
        @provider = Provider.find(provider_id)
        @logger = Logger.new(:auth)
      end

      def authorization_url
        raise NotImplementedError
      end

      def request_token(code)
        raise NotImplementedError
      end

      def refresh_token!
        raise NotImplementedError
      end

      def log(type, message)
        logger.send(type.to_s, message)
      end
    end
  end
end
