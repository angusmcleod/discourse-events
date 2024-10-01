import Component from "@ember/component";
import LoadMore from "discourse/mixins/load-more";
import discourseComputed from "discourse-common/utils/decorators";
import Event from "../models/event";

export default Component.extend(LoadMore, {
  classNames: ["events-event-table"],
  eyelineSelector: ".events-event-row",
  loadingComplete: false,

  @discourseComputed("filter")
  showTopics(filter) {
    return filter === "connected";
  },

  actions: {
    toggleSelectAll() {
      this.toggleProperty("selectAll");
      this.modifySelection(this.events, this.selectAll);
    },

    loadMore() {
      if (this.loading || this.loadingComplete) {
        return;
      }

      const page = this.page + 1;
      let params = {
        page,
      };
      if (this.filter) {
        params.filter = this.filter;
      }
      if (this.asc) {
        params.asc = this.asc;
      }
      if (this.order) {
        params.order = this.order;
      }

      this.set("loading", true);

      Event.list(params)
        .then((result) => {
          if (result.events && result.events.length) {
            this.set("page", page);
            this.get("events").pushObjects(Event.toArray(result.events));
          } else {
            this.set("loadingComplete", true);
          }
        })
        .finally(() => this.set("loading", false));
    },
  },
});
