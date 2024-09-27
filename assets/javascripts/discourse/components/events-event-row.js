import Component from "@ember/component";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend({
  tagName: "tr",
  classNameBindings: [":events-event-row", "selected"],
  selected: false,

  @observes("selectAll")
  toggleWhenSelectAll() {
    this.set("selected", this.selectAll);
  },

  @observes("selected")
  selectEvent() {
    this.modifySelection([this.event], this.selected);
  },

  @discourseComputed("event.provider_id", "providers")
  provider(providerId, providers) {
    return providers.find((provider) => provider.id === providerId);
  },

  @discourseComputed("provider.provider_type")
  providerLabel(providerType) {
    if (providerType) {
      return I18n.t(
        `admin.events.provider.provider_type.${providerType}.label`
      );
    } else {
      return null;
    }
  },
});
