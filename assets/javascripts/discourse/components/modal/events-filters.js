import { A } from "@ember/array";
import Component from "@ember/component";
import { notEmpty } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import Filter from "../../models/filter";

const QUERY_COLUMNS = [
  {
    name: "Event Name",
    id: "name",
  },
];

const QUERY_OPERATORS = [
  {
    name: "Like",
    id: "like",
  },
];

export default Component.extend({
  hasFilters: notEmpty("model.filters"),

  @discourseComputed
  queryColumns() {
    return QUERY_COLUMNS;
  },

  @discourseComputed
  queryOperators() {
    return QUERY_OPERATORS;
  },

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
