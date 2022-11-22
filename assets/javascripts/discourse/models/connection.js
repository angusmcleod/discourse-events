import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { A } from "@ember/array";
import discourseComputed from "discourse-common/utils/decorators";
import Site from "discourse/models/site";

const Connection = EmberObject.extend({
  filters: A(),

  @discourseComputed("category_id")
  category(categoryId) {
    const categories = Site.current().categoriesList;
    return categories.find((c) => c.id === categoryId);
  },
});

Connection.reopenClass({
  all() {
    return ajax("/admin/events/connection").catch(popupAjaxError);
  },

  update(connection) {
    return ajax(`/admin/events/connection/${connection.id}`, {
      type: "PUT",
      contentType: "application/json",
      data: JSON.stringify({ connection }),
    }).catch(popupAjaxError);
  },

  sync(connection) {
    return ajax(`/admin/events/connection/${connection.id}`, {
      type: "POST",
    }).catch(popupAjaxError);
  },

  destroy(connection) {
    return ajax(`/admin/events/connection/${connection.id}`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },
});

export default Connection;
