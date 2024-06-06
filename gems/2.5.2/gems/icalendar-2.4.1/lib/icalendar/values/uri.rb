require "uri"

module Icalendar
  module Values
    class Uri < Value
      def initialize(value, params = {})
        parsed =
          begin
            URI.parse value
          rescue StandardError
            value
          end
        super parsed, params
      end

      def value_ical
        value.to_s
      end
    end
  end
end
