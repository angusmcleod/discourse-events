import { A } from "@ember/array";
import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const Event = EmberObject.extend({
  selected: false,
});

Event.reopenClass({
  list(data = {}) {
    return ajax("/admin/plugins/events/event", {
      type: "GET",
      data,
    }).catch(popupAjaxError);
  },

  listAll(data = {}) {
    return ajax("/admin/plugins/events/event/all", {
      type: "GET",
      data,
    }).catch(popupAjaxError);
  },

  destroy(data) {
    return ajax("/admin/plugins/events/event", {
      type: "DELETE",
      data,
    }).catch(popupAjaxError);
  },

  connect(data) {
    return ajax("/admin/plugins/events/event/connect", {
      type: "POST",
      data,
    }).catch(popupAjaxError);
  },

  toArray(events, selectedEventIds = []) {
    return A(
      events.map((event) => {
        if (selectedEventIds.includes(event.id)) {
          event.selected = true;
        }
        return Event.create(event);
      })
    );
  },
});

export default Event;
