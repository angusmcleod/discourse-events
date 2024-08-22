import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { OAUTH2_TYPES, TOKEN_TYPES } from "../events-provider-row";

export default Component.extend({
  hideCredentials: true,

  @discourseComputed("model.provider_type")
  showToken(providerType) {
    return providerType && TOKEN_TYPES.includes(providerType);
  },

  @discourseComputed("model.provider_type")
  showClientCredentials(providerType) {
    return providerType && OAUTH2_TYPES.includes(providerType);
  },

  actions: {
    toggleHideCredentials() {
      this.toggleProperty("hideCredentials");
    },
  },
});
