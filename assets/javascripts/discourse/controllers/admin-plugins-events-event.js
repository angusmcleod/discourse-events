import { A } from "@ember/array";
import Controller from "@ember/controller";
import { not, notEmpty } from "@ember/object/computed";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import ConfirmEventDeletion from "../components/modal/events-confirm-event-deletion";
import ConnectTopic from "../components/modal/events-connect-topic";
import Message from "../mixins/message";

export default Controller.extend(Message, {
  hasEvents: notEmpty("events"),
  selectedEventIds: A(),
  modal: service(),
  selectAll: false,
  order: null,
  asc: null,
  filter: null,
  queryParams: ["filter"],
  addDisabled: not("subscription.subscribed"),
  subscription: service("events-subscription"),
  router: service(),

  @discourseComputed("selectedEventIds.[]", "hasEvents")
  deleteDisabled(selectedEventIds, hasEvents) {
    return !hasEvents || !selectedEventIds.length;
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

  @discourseComputed("eventsRoute", "filter")
  unconnectedRoute(eventsRoute, filter) {
    return eventsRoute && filter === "unconnected";
  },

  @discourseComputed("eventsRoute", "filter")
  viewName(eventsRoute, filter) {
    return `event.${filter}`;
  },

  @discourseComputed("selectedEventIds.[]")
  connectTopicDisabled(selectedEventIds) {
    return selectedEventIds.length !== 1;
  },

  updateCurrentRouteCount() {
    const events = this.get("events");
    this.set(
      `${this.unconnectedRoute ? "without" : "with"}TopicsCount`,
      events.length
    );
  },

  actions: {
    openConnectTopic() {
      const selectedEventId = this.selectedEventIds[0];
      const event = this.get("events").findBy("id", selectedEventId);

      if (!event) {
        return;
      }

      this.modal.show(ConnectTopic, {
        model: {
          event,
          onConnectTopic: () => {
            this.set("selectedEventIds", A());
            this.get("events").removeObject(event);
          },
        },
      });
    },

    modifySelection(eventIds, selected) {
      this.get("events").forEach((event) => {
        if (eventIds.includes(event.id)) {
          event.set("selected", selected);
        }
      });
      if (selected) {
        this.get("selectedEventIds").addObjects(eventIds);
      } else {
        this.get("selectedEventIds").removeObjects(eventIds);
      }
    },

    openDelete() {
      this.modal.show(ConfirmEventDeletion, {
        model: {
          eventIds: this.selectedEventIds,
          onDestroyEvents: (
            destroyedEventIds = null,
            destroyedTopicsEvents = null
          ) => {
            this.set("selectedEventIds", A());

            const events = this.get("events");

            if (destroyedEventIds) {
              const destroyedEvents = events.filter((e) =>
                destroyedEventIds.includes(e.id)
              );
              events.removeObjects(destroyedEvents);
              this.updateCurrentRouteCount();
            }

            if (destroyedTopicsEvents) {
              const destroyedTopicsEventIds = destroyedTopicsEvents.map(
                (e) => e.id
              );

              events.forEach((event) => {
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
