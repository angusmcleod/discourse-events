import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Source from "../models/source";
import Topic from "discourse/models/topic";
import { A } from "@ember/array";

const Event = EmberObject.extend();

Event.reopenClass({
  list(data = {}) {
    return ajax("/admin/events/event", {
      type: "GET",
      data,
    }).catch(popupAjaxError);
  },

  destroy(data) {
    return ajax("/admin/events/event", {
      type: "DELETE",
      data,
    }).catch(popupAjaxError);
  },

  eventsArray(events) {
    return A(
      events.map((event) => {
        let source = Source.create(event.source);
        let topics = A(event.topics.map((t) => Topic.create(t)));
        return Object.assign(event, { source, topics });
      })
    );
  },
});

export default Event;
