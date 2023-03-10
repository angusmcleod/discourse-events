import ModalFunctionality from "discourse/mixins/modal-functionality";
import Controller from "@ember/controller";
import I18n from "I18n";
import { action } from "@ember/object";

export default Controller.extend(ModalFunctionality, {
  title: "add_event.modal_title",

  @action
  clear() {
    event?.preventDefault();
    this.set("bufferedEvent", null);
  },

  actions: {
    saveEvent() {
      if (this.valid) {
        this.get("model.update")(this.bufferedEvent);
        this.send("closeModal");
      } else {
        this.flash(I18n.t("add_event.error"), "error");
      }
    },

    updateEvent(event, valid) {
      this.set("bufferedEvent", event);
      this.set("valid", valid);
    },
  },
});
