import Component from "@ember/component";
import I18n from "I18n";
import { action } from "@ember/object";

export default Component.extend({
  title: I18n.t("add_event.modal_title"),

  @action
  clear() {
    event?.preventDefault();
    this.set("bufferedEvent", null);
  },

  actions: {
    saveEvent() {
      if (this.valid) {
        this.get("model.update")(this.bufferedEvent);
        this.closeModal();
      } else {
        this.set("flash", I18n.t("add_event.error"));
      }
    },

    updateEvent(event, valid) {
      this.set("bufferedEvent", event);
      this.set("valid", valid);
    },
  },
});
