import Component from "@ember/component";
import { default as discourseComputed } from "discourse-common/utils/decorators";

const QUERY_COLUMNS = [
  {
    name: "Event Name",
    id: "name",
  },
  {
    name: "Start Time",
    id: "start_time",
  },
];

const QUERY_OPERATORS = [
  {
    name: "Like",
    id: "like",
  },
  {
    name: "Greater Than",
    id: "greater_than",
  },
  {
    name: "Less Than",
    id: "less_than",
  },
];

export default Component.extend({
  tagName: "tr",
  classNames: ["filter"],

  @discourseComputed
  queryColumns() {
    return QUERY_COLUMNS;
  },

  @discourseComputed("filter.query_column")
  queryOperators(queryColumn) {
    const operators = QUERY_OPERATORS;
    if (queryColumn === "name") {
      return operators.filter((o) => o.id === "like");
    } else {
      return operators;
    }
  },

  @discourseComputed("filter.query_column")
  dateQueryColumn(queryColumn) {
    return queryColumn === "start_time";
  },

  actions: {
    onChangeDateQueryValue(date) {
      this.filter.set("query_value", date);
    },

    removeFilter() {
      this.removeFilter(this.filter);
    },
  },
});
