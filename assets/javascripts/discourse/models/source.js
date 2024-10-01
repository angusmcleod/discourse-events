import EmberObject from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import Site from "discourse/models/site";
import discourseComputed from "discourse-common/utils/decorators";

const Source = EmberObject.extend({
  @discourseComputed("import_type")
  canImport(importType) {
    return importType === "import" || importType === "import_publish";
  },

  @discourseComputed("category_id")
  category(categoryId) {
    return Site.current().categoriesList.find((c) => c.id === categoryId);
  },
});

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

  destroy(source) {
    return ajax(`/admin/plugins/events/source/${source.id}`, {
      type: "DELETE",
    }).catch(popupAjaxError);
  },

  importEvents(source) {
    return ajax(`/admin/plugins/events/source/${source.id}/import`, {
      type: "POST",
    }).catch(popupAjaxError);
  },

  syncTopics(source) {
    return ajax(`/admin/plugins/events/source/${source.id}/topics`, {
      type: "POST",
    }).catch(popupAjaxError);
  },
});

export default Source;
