import Component from "@ember/component";
import { or } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import { contentsMap } from "../lib/events";
import Provider from "../models/provider";

const TOKEN_TYPES = ["eventbrite", "humanitix", "eventzilla"];

const NO_AUTH_TYPES = ["icalendar"];

const OAUTH2_TYPES = ["meetup"];

const PROVIDER_TYPES = [...NO_AUTH_TYPES, ...TOKEN_TYPES, ...OAUTH2_TYPES];

export default Component.extend({
  tagName: "tr",
  classNames: ["events-provider-row"],
  attributeBindings: ["provider.id:data-provider-id"],
  hideCredentials: true,
  hasSecretCredentials: or("showToken", "showClientCredentials"),

  didReceiveAttrs() {
    this._super();
    this.set("currentProvider", JSON.parse(JSON.stringify(this.provider)));
  },

  @discourseComputed("provider.name", "provider.url", "provider.provider_type")
  providerChanged(name, url, type) {
    const cp = this.currentProvider;
    return cp.name !== name || cp.url !== url || cp.provider_type !== type;
  },

  @discourseComputed("providerChanged")
  saveDisabled(providerChanged) {
    return !providerChanged;
  },

  @discourseComputed("providerChanged")
  saveClass(providerChanged) {
    return providerChanged ? "save-provider btn-primary" : "save-provider";
  },

  @discourseComputed
  providerTypes() {
    return contentsMap(PROVIDER_TYPES);
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
  showToken(providerType) {
    return providerType && TOKEN_TYPES.includes(providerType);
  },

  @discourseComputed("provider.provider_type")
  showNoAuth(providerType) {
    return !providerType || NO_AUTH_TYPES.includes(providerType);
  },

  @discourseComputed("provider.provider_type")
  showClientCredentials(providerType) {
    return providerType && OAUTH2_TYPES.includes(providerType);
  },

  actions: {
    toggleHideCredentials() {
      this.toggleProperty("hideCredentials");
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
          } else if (this.currentSource.id !== "new") {
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
      window.location.href = `/admin/events/provider/${this.provider.id}/authorize`;
    },
  },
});
