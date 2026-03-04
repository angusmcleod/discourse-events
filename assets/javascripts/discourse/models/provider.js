import { A } from "@ember/array";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import singleton from "discourse/lib/singleton";
import RestModel from "discourse/models/rest";
import discourseComputed from "discourse-common/utils/decorators";

export const TOKEN_TYPES = ["eventbrite", "humanitix", "eventzilla"];
export const NO_AUTH_TYPES = ["icalendar"];
export const OAUTH2_TYPES = ["meetup", "outlook", "google"];

@singleton
export default class Provider extends RestModel {
  @discourseComputed("id")
  stored(providerId) {
    return providerId && providerId !== "new";
  }

  @discourseComputed("hasCredentials", "stored", "authenticated")
  status(hasCredentials, providerStored, providerAuthenticated) {
    if (hasCredentials) {
      return providerAuthenticated ? "ready" : "not_authenticated";
    } else {
      return providerStored ? "ready" : "not_ready";
    }
  }

  @discourseComputed("provider_type")
  hasCredentials(providerType) {
    return providerType && !NO_AUTH_TYPES.includes(providerType);
  }
}

Provider.reopenClass({
  all() {
    return ajax("/admin/plugins/events/provider").catch(popupAjaxError);
  },

  update(provider) {
    return ajax(`/admin/plugins/events/provider/${provider.id}`, {
      type: "PUT",
      data: {
        provider,
      },
    }).catch(popupAjaxError);
  },

  destroy(provider) {
    return ajax(`/admin/plugins/events/provider/${provider.id}`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },

  toArray(store, providers) {
    return A(
      providers.map((provider) => {
        return store.createRecord("provider", provider);
      })
    );
  },
});
