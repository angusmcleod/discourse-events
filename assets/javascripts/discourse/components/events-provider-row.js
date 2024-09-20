import Component from "@ember/component";
import { service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import Provider from "../models/provider";
import EventsProviderCredentials from "./modal/events-provider-credentials";

export const TOKEN_TYPES = ["eventbrite", "humanitix", "eventzilla"];
export const NO_AUTH_TYPES = ["icalendar"];
export const OAUTH2_TYPES = ["meetup", "outlook", "google"];

export default Component.extend({
  tagName: "tr",
  classNames: ["events-provider-row"],
  attributeBindings: ["provider.id:data-provider-id"],
  modal: service(),
  subscription: service("events-subscription"),

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
      return !this.subscription.supportsFeatureValue("provider", providerType);
    }
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

  @discourseComputed("provider.provider_type")
  canAuthenicate(providerType) {
    return providerType && OAUTH2_TYPES.includes(providerType);
  },

  @discourseComputed("provider.provider_type")
  noCredentials(providerType) {
    return !providerType || NO_AUTH_TYPES.includes(providerType);
  },

  actions: {
    openCredentials() {
      this.modal.show(EventsProviderCredentials, {
        model: this.get("provider"),
      });
    },

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
  },
});
