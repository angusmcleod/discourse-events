import Component from "@ember/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { classNames } from "@ember-decorators/component";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import EventRsvpModel, { rsvpTypes } from "../models/event-rsvp";
import EventRsvpModal from "./modal/event-rsvp";

@classNames("event-rsvp")
export default class EventRsvp extends Component {
  @service modal;
  @service currentUser;
  updatingRsvp = false;

  @action
  updateRsvp(type) {
    this.set("updatingRsvp", true);

    const data = {
      type,
      username: this.currentUser.username,
      topic_id: this.get("topic.id"),
    };
    EventRsvpModel.save(data).then(() => {
      this.setProperties({
        updatingRsvp: false,
        "topic.event_user": {
          rsvp: type,
        },
      });
    });
  }

  @discourseComputed
  rsvpOptions() {
    return rsvpTypes
      .filter((rsvpType) => rsvpType !== "invited")
      .map((rsvpType) => {
        return {
          id: rsvpType,
          name: I18n.t(`event_rsvp.${rsvpType}.label`),
        };
      });
  }

  @action
  openModal() {
    event?.preventDefault();
    this.modal.show(EventRsvpModal, {
      model: {
        topic: this.get("topic"),
      },
    });
  }
}
