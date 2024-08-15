import { A } from "@ember/array";
import Component from "@ember/component";
import { notEmpty } from "@ember/object/computed";
import Filter from "../../models/filter";

export default Component.extend({
  hasFilters: notEmpty("model.filters"),

  didInsertElement() {
    this._super(...arguments);

    if (!this.model.filters) {
      this.model.set("filters", A());
    }
  },

  actions: {
    addFilter() {
      const filter = Filter.create({ id: "new" });
      this.model.get("filters").pushObject(filter);
    },

    removeFilter(filter) {
      this.model.get("filters").removeObject(filter);
    },
  },
});
