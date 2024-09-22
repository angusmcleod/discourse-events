import { A } from "@ember/array";
import Controller from "@ember/controller";
import { notEmpty } from "@ember/object/computed";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import ConfirmEventDeletion from "../components/modal/events-confirm-event-deletion";
import Message from "../mixins/message";

export default Controller.extend(Message, {
  hasEvents: notEmpty("events"),
  selectedEvents: A(),
  modal: service(),
  selectAll: false,
  order: null,
  asc: null,
  filter: "topics",
  viewName: "event",
  queryParams: ["filter"],

  @discourseComputed("selectedEvents.[]", "hasEvents")
  deleteDisabled(selectedEvents, hasEvents) {
    return !hasEvents || !selectedEvents.length;
  },

  @discourseComputed("hasEvents")
  selectDisabled(hasEvents) {
    return !hasEvents;
  },

  @discourseComputed("filter")
  noneLabel(filter) {
    return I18n.t(
      `admin.events.event.none.${filter === "topics" ? "topics" : "unattached"}`
    );
  },

  actions: {
    modifySelection(events, checked) {
      if (checked) {
        this.get("selectedEvents").pushObjects(events);
      } else {
        this.get("selectedEvents").removeObjects(events);
      }
    },

    openDelete() {
      this.modal.show(ConfirmEventDeletion, {
        model: {
          events: this.selectedEvents,
          onDestroyEvents: (
            destroyedEvents = null,
            destroyedTopicsEvents = null
          ) => {
            this.set("selectedEvents", A());

            if (destroyedEvents) {
              this.get("events").removeObjects(destroyedEvents);
            }

            if (destroyedTopicsEvents) {
              const destroyedTopicsEventIds = destroyedTopicsEvents.map(
                (e) => e.id
              );

              this.get("events").forEach((event) => {
                if (destroyedTopicsEventIds.includes(event.id)) {
                  event.set("topics", null);
                }
              });
            }
          },
        },
      });
    },
  },
});
