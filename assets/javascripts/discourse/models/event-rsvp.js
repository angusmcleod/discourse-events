import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const EventRsvp = EmberObject.extend();
const basePath = "/discourse-events/rsvp";
export const rsvpTypes = ["going", "not_going", "maybe_going", "invited"];

EventRsvp.reopenClass({
  save(data) {
    return ajax(`${basePath}/update`, {
      type: "PUT",
      data,
    }).catch(popupAjaxError);
  },

  list(data) {
    return ajax(`${basePath}/users`, {
      data,
    }).catch(popupAjaxError);
  },
});

export default EventRsvp;
