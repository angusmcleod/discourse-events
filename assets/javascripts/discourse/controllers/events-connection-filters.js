import Controller from "@ember/controller";
import ModalFunctionality from "discourse/mixins/modal-functionality";
import discourseComputed from "discourse-common/utils/decorators";
import ConnectionFilter from "../models/connection-filter";
import { A } from "@ember/array";

const QUERY_COLUMNS = [
  {
    name: "Event Name",
    id: "name",
  },
];

export default Controller.extend(ModalFunctionality, {
  @discourseComputed
  queryColumns() {
    return QUERY_COLUMNS;
  },

  onShow() {
    if (!this.model.connection.filters) {
      this.model.connection.set("filters", A());
    }
  },

  actions: {
    addFilter() {
      const filter = ConnectionFilter.create({ id: "new" });
      this.model.connection.get("filters").pushObject(filter);
    },

    removeFilter(filter) {
      this.model.connection.get("filters").removeObject(filter);
    },
  },
});
