import Component from "@ember/component";
import LoadMore from "discourse/mixins/load-more";
import Event from "../models/event";

export default Component.extend(LoadMore, {
  classNames: ["events-event-table"],
  eyelineSelector: ".events-event-row",
  loadingComplete: false,

  actions: {
    toggleSelectAll() {
      this.toggleProperty("selectAll");
      this.modifySelection(this.events, this.selectAll);
    },

    loadMore() {
      if (this.loading || this.loadingComplete) {
        return;
      }

      let page = this.page + 1;
      this.set("page", page);
      this.set("loading", true);

      Event.list({ page })
        .then((result) => {
          if (result.events && result.events.length) {
            this.get("events").pushObjects(Event.eventsArray(result.events));
          } else {
            this.set("loadingComplete", true);
          }
        })
        .finally(() => this.set("loading", false));
    },
  },
});
