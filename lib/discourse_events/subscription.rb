# frozen_string_literal: true
module DiscourseEvents
  class Subscription
    BUCKETS = {
      community: "discourse-events-gems-us",
      business: "discourse-events-gems-us"
    }
    GEMS = {
      community: {
        omnievent: "0.1.0.pre8",
        omnievent_icalendar: "0.1.0.pre5"
      },
      business: {
        omnievent: "0.1.0.pre8",
        omnievent_icalendar: "0.1.0.pre5",
        omnievent_api: "0.1.0.pre3",
        omnievent_outlook: "0.1.0.pre7",
        omnievent_google: "0.1.0.pre4"
      }
    }

    attr_accessor :subscriptions

    def self.setup
      new.setup
    end

    def setup
      return unless database_ready?

      @subscriptions = ::DiscourseSubscriptionClient.find_subscriptions("discourse-events")
      install if subscription_slug
    end

    def install
      source = subscriptions.resource.get_source_url(BUCKETS[subscription_slug])
      return unless source

      GEMS[subscription_slug].each do |gem_slug, version|
        klass = gem_slug.to_s.underscore.classify
        next if installed?(klass)

        gem_name = gem_slug.to_s.dasherize 
        opts = {
          require_name: gem_slug.to_s.gsub(/\_/, '/'),
          source: source
        }
        PluginGem.load(plugin_path, gem_name, version, opts)
      end
    end

    def installed?(klass)
      defined?(klass) == 'constant' && klass.class == Module
    end

    def subscription_slug
      @subscription ||= begin
        if business?
          :business
        elsif community?
          :community
        else
          nil
        end
      end
    end

    def community?
      @community ||= begin
        return nil unless subscriptions && subscriptions.subscriptions
        subscriptions.subscriptions.any? { |s| s.product_name == 'Community' }
      end
    end

    def business?
      @business ||= begin
        return nil unless subscriptions && subscriptions.subscriptions
        subscriptions.subscriptions.any? { |s| s.product_name == 'Business' }
      end
    end

    def database_ready?
      ActiveRecord::Base.connection&.table_exists? 'subscription_client_subscriptions'
    rescue ActiveRecord::NoDatabaseError
      false
    end

    def plugin_path
      @plugin_path ||= Discourse.plugins_by_name['discourse-events'].path
    end
  end
end