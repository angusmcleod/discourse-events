import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const Provider = EmberObject.extend();

Provider.reopenClass({
  all() {
    return ajax("/admin/events/provider").catch(popupAjaxError);
  },

  update(provider) {
    return ajax(`/admin/events/provider/${provider.id}`, {
      type: "PUT",
      data: {
        provider,
      },
    }).catch(popupAjaxError);
  },

  destroy(provider) {
    return ajax(`/admin/events/provider/${provider.id}`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },
});

export default Provider;
