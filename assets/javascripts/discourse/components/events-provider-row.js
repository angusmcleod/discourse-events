import Component from "@ember/component";
import { not } from "@ember/object/computed";
import { service } from "@ember/service";
import DiscourseURL from "discourse/lib/url";
import discourseComputed from "discourse-common/utils/decorators";
import Provider, { OAUTH2_TYPES } from "../models/provider";

export default Component.extend({
  tagName: "tr",
  classNames: ["events-provider-row"],
  attributeBindings: ["provider.id:data-provider-id"],
  modal: service(),
  subscription: service("events-subscription"),
  removeDisabled: not("subscription.subscribed"),

  didReceiveAttrs() {
    this._super();
    this.set("currentProvider", JSON.parse(JSON.stringify(this.provider)));
  },

  @discourseComputed(
    "provider.name",
    "provider.url",
    "provider.provider_type",
    "provider.token",
    "provider.client_id",
    "provider.client_secret"
  )
  providerChanged(name, url, type, token, clientId, clientSecret) {
    const current = this.currentProvider;
    return (
      current.name !== name ||
      current.url !== url ||
      current.provider_type !== type ||
      current.token !== token ||
      current.client_id !== clientId ||
      current.client_secret !== clientSecret
    );
  },

  @discourseComputed(
    "provider.name",
    "provider.provider_type",
    "providerChanged"
  )
  saveDisabled(providerName, providerType, providerChanged) {
    if (!providerName || !providerChanged || !providerType) {
      return true;
    } else {
      return !this.subscription.supportsFeatureValue(
        "provider",
        "provider_type",
        providerType
      );
    }
  },

  @discourseComputed("provider.provider_type", "provider.inSubscription")
  canSave(providerType, inSubscription) {
    return inSubscription && providerType !== "icalendar";
  },

  @discourseComputed("providerChanged")
  saveClass(providerChanged) {
    return providerChanged ? "save-provider btn-primary" : "save-provider";
  },

  @discourseComputed(
    "canAuthenicate",
    "providerChanged",
    "provider.authenticated"
  )
  authenticateDisabled(canAuthenicate, providerChanged, providerAuthenticated) {
    return !canAuthenicate || providerChanged || providerAuthenticated;
  },

  @discourseComputed("authenticateDisabled")
  authenticateClass(authenticateDisabled) {
    return authenticateDisabled ? "" : "btn-primary";
  },

  @discourseComputed("provider.provider_type", "provider.inSubscription")
  canAuthenicate(providerType, inSubscription) {
    return (
      inSubscription && providerType && OAUTH2_TYPES.includes(providerType)
    );
  },

  @discourseComputed("provider.provider_type")
  providerLogo(providerType) {
    return `/plugins/discourse-events/logos/${providerType}.svg`;
  },

  @discourseComputed("subscription.features.provider", "provider.provider_type")
  supportedSubscriptions(subscriptionProviders, providerType) {
    if (!subscriptionProviders) {
      return [];
    }
    const subscriptions = subscriptionProviders["provider_type"][providerType];
    return Object.keys(subscriptions).filter((type) => subscriptions[type]);
  },

  @discourseComputed("provider.status")
  showAuthenticate(providerStatus) {
    return providerStatus && providerStatus === "not_authenticated";
  },

  @discourseComputed("provider.status")
  showUpgradeSubscription(providerStatus) {
    return providerStatus && providerStatus === "not_in_subscription";
  },

  actions: {
    saveProvider() {
      const provider = JSON.parse(JSON.stringify(this.provider));

      if (!provider.name) {
        return;
      }

      this.set("saving", true);

      Provider.update(provider)
        .then((result) => {
          if (result) {
            this.setProperties({
              currentProvider: result.provider,
              provider: Provider.create(result.provider),
            });
          } else if (this.currentProvider.id !== "new") {
            this.set(
              "provider",
              JSON.parse(JSON.stringify(this.currentProvider))
            );
          }
        })
        .finally(() => {
          this.set("saving", false);
        });
    },

    authenticateProvider() {
      window.location.href = `/admin/plugins/events/provider/${this.provider.id}/authorize`;
    },

    upgradeSubscription() {
      DiscourseURL.routeTo(this.subscription.upgradePath);
    },
  },
});
