import { A } from "@ember/array";
import Controller, { inject as controller } from "@ember/controller";
import { not, notEmpty } from "@ember/object/computed";
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
  filter: null,
  queryParams: ["filter"],
  addDisabled: not("subscription.subscribed"),
  subscription: service("events-subscription"),
  router: service(),
  connections: controller("admin-plugins-events-event-connection"),

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
      `admin.events.event.none.${
        filter === "connected" ? "connected" : "unconnected"
      }`
    );
  },

  @discourseComputed("router.currentRouteName")
  eventsRoute(currentRouteName) {
    return currentRouteName === "adminPlugins.events.event.index";
  },

  @discourseComputed("router.currentRouteName")
  connectionRoute(currentRouteName) {
    return currentRouteName === "adminPlugins.events.event.connection";
  },

  @discourseComputed("eventsRoute", "filter")
  viewName(eventsRoute, filter) {
    return eventsRoute ? `event.${filter}` : "connection";
  },

  actions: {
    addConnection() {
      if (this.connectionRoute) {
        this.connections.addConnection();
      }
    },

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
