import Component from "@ember/component";
import { service } from "@ember/service";
import { default as discourseComputed } from "discourse-common/utils/decorators";
import { eventLabel } from "../lib/date-utilities";
import AddEvent from "./modal/add-event";

export default Component.extend({
  classNames: ["event-label"],
  modal: service(),

  didInsertElement() {
    this._super(...arguments);
    $(".title-and-category").toggleClass(
      "event-add-no-text",
      this.get("iconOnly")
    );
  },

  @discourseComputed("noText")
  valueClasses(noText) {
    let classes = "add-event";
    if (noText) {
      classes += " btn-primary";
    }
    return classes;
  },

  @discourseComputed("event")
  valueLabel(event) {
    return eventLabel(event, {
      noText: this.get("noText"),
      useEventTimezone: true,
      showRsvp: true,
      siteSettings: this.siteSettings,
    });
  },

  @discourseComputed("category", "noText")
  iconOnly(category, noText) {
    return (
      noText ||
      this.siteSettings.events_event_label_no_text ||
      Boolean(
        category && category.get("custom_fields.events_event_label_no_text")
      )
    );
  },

  actions: {
    showAddEvent() {
      this.modal.show(AddEvent, {
        model: {
          bufferedEvent: this.event,
          event: this.event,
          update: (event) => {
            this.set("event", event);
          },
        },
      });
    },

    removeEvent() {
      this.set("event", null);
    },
  },
});
