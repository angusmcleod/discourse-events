# frozen_string_literal: true
module DiscourseEvents
  class SubscriptionManager
    PRODUCTS = { community: "Community", business: "Business" }
    BUCKETS = { community: "discourse-events-gems-us", business: "discourse-events-gems-us" }
    GEMS = {
      community: {
        omnievent: "0.1.0.pre8",
        omnievent_icalendar: "0.1.0.pre5",
      },
      business: {
        omnievent: "0.1.0.pre8",
        omnievent_icalendar: "0.1.0.pre5",
        omnievent_api: "0.1.0.pre3",
        omnievent_outlook: "0.1.0.pre7",
        omnievent_google: "0.1.0.pre4",
      },
    }

    attr_accessor :subscriptions

    def features
      result = {
        provider: {
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
        source: {
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
        connection: {
          discourse_events: {
            none: false,
            community: true,
            business: true,
          },
        },
      }

      if DiscourseEvents::Connection.available_clients.include?("discourse_calendar")
        result[:connection][:discourse_calendar] = { none: false, community: false, business: true }
      end

      result
    end

    def self.setup(update: false, install: false)
      new.setup(update: update, install: install)
    end

    def ready?
      database_ready? && client_installed?
    end

    def setup(update: false, install: false)
      return unless ready?
      perform_update if update
      perform_install if subscribed? && install
    end

    def perform_update
      ::DiscourseSubscriptionClient::Subscriptions.update
    end

    def perform_install
      return unless source_url

      GEMS[product.to_sym].each do |gem_slug, version|
        klass = gem_slug.to_s.underscore.classify
        gem_name = gem_slug.to_s.dasherize
        opts = { require_name: gem_slug.to_s.gsub(/\_/, "/"), source: source_url }
        PluginGem.load(plugin_path, gem_name, version, opts)
      end
    end

    def installed?(klass)
      defined?(klass) == "constant" && klass.class == Module
    end

    def subscribed?
      return true if ENV["DISCOURSE_EVENTS_PRODUCT"].present?
      subscription.present?
    end

    def supports_import?
      supports_feature_value?(:source, :import) || supports_feature_value?(:source, :import_publish)
    end

    def supports_publish?
      supports_feature_value?(:source, :publish) ||
        supports_feature_value?(:source, :import_publish)
    end

    def supports_feature_value?(feature, value)
      return true unless feature && value
      return false unless product
      features[feature.to_sym][value.to_sym][product.to_sym]
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

    def client_installed?
      defined?(DiscourseSubscriptionClient) == "constant" &&
        DiscourseSubscriptionClient.class == Module
    end

    def plugin_path
      @plugin_path ||= Discourse.plugins_by_name["discourse-events"].path
    end

    def source_url
      @source_url ||=
        begin
          return ENV["DISCOURSE_EVENTS_SOURCE_URL"] if ENV["DISCOURSE_EVENTS_SOURCE_URL"].present?
          subscriptions.resource.get_source_url(BUCKETS[product])
        end
    end
  end
end
