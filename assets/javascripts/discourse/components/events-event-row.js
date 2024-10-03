import Component from "@ember/component";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend({
  tagName: "tr",
  classNameBindings: [":events-event-row", "event.selected:selected"],

  @observes("event.selected")
  selectEvent() {
    this.modifySelection([this.event.id], this.event.selected);
  },

  @discourseComputed("event.provider_id", "providers")
  provider(providerId, providers) {
    return providers.find((provider) => provider.id === providerId);
  },

  click() {
    this.set("event.selected", !this.get("event.selected"));
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
