import { tracked } from "@glimmer/tracking";
import Component from "@ember/component";
import { action } from "@ember/object";
import I18n from "I18n";

export default class AddEvent extends Component {
  @tracked bufferedEvent = this.model.event;
  title = I18n.t("add_event.modal_title");
  valid = true;

  @action
  clear() {
    event?.preventDefault();
    this.bufferedEvent = null;
  }

  @action
  saveEvent() {
    if (this.valid) {
      this.get("model.update")(this.bufferedEvent);
      this.closeModal();
    } else {
      this.flash = I18n.t("add_event.error");
    }
  }

  @action
  updateEvent(event, valid) {
    this.bufferedEvent = event;
    this.valid = valid;
  }
}
