# frozen_string_literal: true
module DiscourseEvents
  class SubscriptionManager
    PRODUCTS = { community: "Community", business: "Business" }
    BUCKETS = { community: "discourse-events-gems-us", business: "discourse-events-gems-us" }
    GEMS = {
      community: {
        omnievent: "0.1.0.pre9",
        omnievent_icalendar: "0.1.0.pre7",
      },
      business: {
        omnievent: "0.1.0.pre9",
        omnievent_icalendar: "0.1.0.pre7",
        omnievent_api: "0.1.0.pre5",
        omnievent_outlook: "0.1.0.pre10",
        omnievent_google: "0.1.0.pre7",
      },
    }

    attr_accessor :subscriptions

    def features
      result = {
        provider: {
          provider_type: {
            icalendar: {
              none: false,
              community: true,
              business: true,
            },
            google: {
              none: false,
              community: false,
              business: true,
            },
            outlook: {
              none: false,
              community: false,
              business: true,
            },
          },
        },
        source: {
          import_type: {
            import: {
              none: false,
              community: true,
              business: true,
            },
            import_publish: {
              none: false,
              community: false,
              business: true,
            },
            publish: {
              none: false,
              community: false,
              business: true,
            },
          },
          topic_sync: {
            manual: {
              none: false,
              community: true,
              business: true,
            },
            auto: {
              none: false,
              community: false,
              business: true,
            },
          },
          client: {
            discourse_events: {
              none: false,
              community: true,
              business: true,
            },
          },
        },
      }

      if DiscourseEvents::Source.available_clients.include?("discourse_calendar")
        result[:source][:client][:discourse_calendar] = {
          none: false,
          community: false,
          business: true,
        }
      end

      result
    end

    def self.setup(update: false, install: false)
      new.setup(update: update, install: install)
    end

    def ready?
      omnievent_installed?
    end

    def ready_to_setup?
      database_ready? && subscription_client_installed?
    end

    def setup(update: false, install: false)
      return unless ready_to_setup?
      perform_update if update
      perform_install if subscribed? && install
    end

    def perform_update
      ::DiscourseSubscriptionClient::Subscriptions.update
    end

    def perform_install
      gem_manager =
        S3GemManager.new(
          access_key_id: s3_access_key_id,
          secret_access_key: s3_secret_access_key,
          region: s3_region,
          bucket: s3_bucket,
        )
      return unless gem_manager.ready?
      gem_manager.install(GEMS[product.to_sym])
    end

    def s3_access_key_id
      ENV["DISCOURSE_EVENTS_GEMS_GEMS_S3_ACCESS_KEY_ID"] || subscriptions.resource.access_key_id
    end

    def s3_secret_access_key
      ENV["DISCOURSE_EVENTS_GEMS_S3_SECRET_ACCESS_KEY"] || subscriptions.resource.secret_access_key
    end

    def s3_region
      ENV["DISCOURSE_EVENTS_GEMS_S3_REGION"] || subscriptions.resource.region
    end

    def s3_bucket
      ENV["DISCOURSE_EVENTS_GEMS_S3_BUCKET"] || BUCKETS[product]
    end

    def subscribed?
      return true if ENV["DISCOURSE_EVENTS_PRODUCT"].present?
      subscription.present?
    end

    def supports_import?
      supports?(:source, :import_type, :import) || supports?(:source, :import_type, :import_publish)
    end

    def supports_publish?
      supports?(:source, :import_type, :publish) ||
        supports?(:source, :import_type, :import_publish)
    end

    def supports?(feature, attribute, value)
      return true unless feature && attribute && value
      return false unless product
      features.dig(feature.to_sym, attribute.to_sym, value.to_sym, product.to_sym)
    end

    def subscriptions
      @subscriptions ||= ::DiscourseSubscriptionClient.find_subscriptions("discourse-events")
    end

    def subscription
      @subscription ||=
        begin
          return business_subscription if business_subscription.present?
          return community_subscription if community_subscription.present?
          nil
        end
    end

    def product
      @product ||=
        begin
          return ENV["DISCOURSE_EVENTS_PRODUCT"] if ENV["DISCOURSE_EVENTS_PRODUCT"].present?
          return nil unless subscription
          PRODUCTS.key(subscription.product_name)
        end
    end

    def community_subscription
      @community_subscription ||=
        begin
          return nil unless subscriptions && subscriptions.subscriptions
          subscriptions.subscriptions.find do |subscription|
            subscription.product_name == PRODUCTS[:community]
          end
        end
    end

    def business_subscription
      @business_subscription ||=
        begin
          return nil unless subscriptions && subscriptions.subscriptions
          subscriptions.subscriptions.find do |subscription|
            subscription.product_name == PRODUCTS[:business]
          end
        end
    end

    def database_ready?
      ActiveRecord::Base.connection&.table_exists? "subscription_client_subscriptions"
    rescue ActiveRecord::NoDatabaseError
      false
    end

    def subscription_client_installed?
      defined?(DiscourseSubscriptionClient) == "constant" &&
        DiscourseSubscriptionClient.class == Module
    end

    def omnievent_installed?
      defined?(OmniEvent) == "constant" && OmniEvent.class == Module
    end
  end
end
