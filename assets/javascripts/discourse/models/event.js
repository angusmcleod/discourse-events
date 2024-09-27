import { A } from "@ember/array";
import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const Event = EmberObject.extend();

Event.reopenClass({
  list(data = {}) {
    return ajax("/admin/plugins/events/event", {
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

  toArray(events) {
    return A(
      events.map((event) => {
        return Event.create(event);
      })
    );
  },
});

export default Event;
