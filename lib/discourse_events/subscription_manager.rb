# frozen_string_literal: true
module DiscourseEvents
  class SubscriptionManager
    def features
      result = {
        provider: {
          provider_type: {
            icalendar: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
            google: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
            outlook: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
          },
        },
        source: {
          import_type: {
            import: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
            import_publish: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
            publish: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
          },
          topic_sync: {
            manual: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
            auto: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
          },
          client: {
            discourse_events: {
              none: true,
              community: true,
              business: true,
              enterprise: true,
            },
          },
        },
      }

      if DiscourseEvents::Source.available_clients.include?("discourse_calendar")
        result[:source][:client][:discourse_calendar] = {
          none: true,
          community: true,
          business: true,
          enterprise: true,
        }
      end

      result
    end

    def ready?
      true
    end

    def product
      :enterprise
    end
  end
end
