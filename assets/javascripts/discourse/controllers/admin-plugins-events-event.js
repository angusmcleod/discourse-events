import { A } from "@ember/array";
import Controller from "@ember/controller";
import { action } from "@ember/object";
import { not, notEmpty } from "@ember/object/computed";
import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import ConfirmEventDeletion from "../components/modal/events-confirm-event-deletion";
import ConnectTopic from "../components/modal/events-connect-topic";
import Message from "../mixins/message";
import Event from "../models/event";

export default class AdminPluginsEventsEvent extends Controller.extend(
  Message
) {
  @service modal;
  @service("events-subscription") subscription;
  @service router;
  @notEmpty("events") hasEvents;
  selectedEventIds = A();

  selectAll = false;
  order = "";
  asc = null;
  filter = null;
  queryParams = ["filter", "order", "asc"];
  @not("subscription.subscribed") addDisabled;

  loadingComplete = false;
  loading = false;

  @discourseComputed("selectedEventIds.[]", "hasEvents")
  deleteDisabled(selectedEventIds, hasEvents) {
    return !hasEvents || !selectedEventIds.length;
  }

  @discourseComputed("hasEvents")
  selectDisabled(hasEvents) {
    return !hasEvents;
  }

  @discourseComputed("filter")
  noneLabel(filter) {
    return I18n.t(
      `admin.events.event.none.${
        filter === "connected" ? "connected" : "unconnected"
      }`
    );
  }

  @discourseComputed("filter")
  unconnectedRoute(filter) {
    return filter === "unconnected";
  }

  @discourseComputed("filter")
  connectedRoute(filter) {
    return filter === "connected";
  }

  @discourseComputed("filter")
  viewName(filter) {
    return `event.${filter}`;
  }

  @discourseComputed("selectedEventIds.[]")
  connectTopicDisabled(selectedEventIds) {
    return selectedEventIds.length !== 1;
  }

  @discourseComputed("selectedEventIds.[]")
  updateTopicDisabled(selectedEventIds) {
    return selectedEventIds.length !== 1;
  }

  updateCurrentRouteCount() {
    const events = this.get("events");
    this.set(
      `${this.unconnectedRoute ? "without" : "with"}TopicsCount`,
      events.length
    );
  }

  @discourseComputed("filter")
  showTopics(filter) {
    return filter === "connected";
  }

  selectAllEvents() {
    Event.listAll({ filter: this.filter }).then((result) => {
      this.modifySelection(result.event_ids, true);
    });
  }

  @action
  toggleSelectAll() {
    this.toggleProperty("selectAll");

    if (this.selectAll) {
      this.selectAllEvents();
    } else {
      this.modifySelection(this.selectedEventIds, false);
    }
  }

  @action
  loadMore() {
    if (this.loading || this.loadingComplete) {
      return;
    }

    const page = this.page + 1;
    let params = {
      page,
    };
    if (this.filter) {
      params.filter = this.filter;
    }
    if (this.asc) {
      params.asc = this.asc;
    }
    if (this.order) {
      params.order = this.order;
    }

    this.set("loading", true);

    Event.list(params)
      .then((result) => {
        if (result.events && result.events.length) {
          this.set("page", page);
          this.get("events").pushObjects(
            Event.toArray(result.events, this.selectedEventIds)
          );
        } else {
          this.set("loadingComplete", true);
        }
      })
      .finally(() => this.set("loading", false));
  }

  @action
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
  }

  @action
  updateTopic() {
    const selectedEventId = this.selectedEventIds[0];
    const event = this.get("events").findBy("id", selectedEventId);

    if (!event) {
      return;
    }

    this.set("updating", true);

    Event.updateTopic({ event_id: event.id })
      .then((result) => {
        if (result.success) {
          this.set("selectedEventIds", A());
        }
      })
      .finally(() => this.set("updating", false));
  }

  @action
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
  }

  @action
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
  }

  @action
  updateOrder(field, asc) {
    this.setProperties({
      order: field,
      asc,
    });
  }
}
