import { A } from "@ember/array";
import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import discourseComputed from "discourse-common/utils/decorators";

const Provider = EmberObject.extend({
  @discourseComputed("id")
  stored(providerId) {
    return providerId && providerId !== "new";
  },
});

Provider.reopenClass({
  all() {
    return ajax("/admin/plugins/events/provider").catch(popupAjaxError);
  },

  update(provider) {
    return ajax(`/admin/plugins/events/provider/${provider.id}`, {
      type: "PUT",
      data: {
        provider,
      },
    }).catch(popupAjaxError);
  },

  destroy(provider) {
    return ajax(`/admin/plugins/events/provider/${provider.id}`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },

  toArray(providers) {
    return A(
      providers.map((provider) => {
        return Provider.create(provider);
      })
    );
  },
});

export default Provider;
