import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const Source = EmberObject.extend();

Source.reopenClass({
  all() {
    return ajax("/admin/plugins/events/source").catch(popupAjaxError);
  },

  update(source) {
    return ajax(`/admin/plugins/events/source/${source.id}`, {
      type: "PUT",
      contentType: "application/json",
      data: JSON.stringify({ source }),
    }).catch(popupAjaxError);
  },

  import(source) {
    return ajax(`/admin/plugins/events/source/${source.id}`, {
      type: "POST",
    }).catch(popupAjaxError);
  },

  destroy(source) {
    return ajax(`/admin/plugins/events/source/${source.id}`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },
});

export default Source;
