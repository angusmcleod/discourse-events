import { A } from "@ember/array";
import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Topic from "discourse/models/topic";
import Source from "../models/source";

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

  eventsArray(events) {
    return A(
      events.map((event) => {
        let attrs = {};
        if (event.source) {
          attrs.source = Source.create(event.source);
        }
        attrs.topics = A(event.topics.map((t) => Topic.create(t)));
        return Object.assign(event, attrs);
      })
    );
  },
});

export default Event;
