import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import { OAUTH2_TYPES, TOKEN_TYPES } from "../models/provider";

export default Component.extend({
  hideCredentials: true,

  @discourseComputed("provider.provider_type")
  title(providerType) {
    const providerLabel = I18n.t(
      `admin.events.provider.provider_type.${providerType}`
    );
    const credsLabel = I18n.t("admin.events.provider.credentials.label");
    return `${providerLabel} ${credsLabel}`;
  },

  @discourseComputed("provider.provider_type")
  showToken(providerType) {
    return providerType && TOKEN_TYPES.includes(providerType);
  },

  @discourseComputed("provider.provider_type")
  showClientCredentials(providerType) {
    return providerType && OAUTH2_TYPES.includes(providerType);
  },

  actions: {
    toggleHideCredentials() {
      this.toggleProperty("hideCredentials");
    },
  },
});
