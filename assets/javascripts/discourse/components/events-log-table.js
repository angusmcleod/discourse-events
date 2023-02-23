import Component from "@ember/component";
import LoadMore from "discourse/mixins/load-more";
import Log from "../models/log";

export default Component.extend(LoadMore, {
  classNames: ["events-log-table"],
  eyelineSelector: ".events-log-row",
  loadingComplete: false,

  actions: {
    loadMore() {
      if (this.loading || this.loadingComplete) {
        return;
      }

      let page = this.page + 1;
      this.set("page", page);
      this.set("loading", true);

      Log.list({ page })
        .then((result) => {
          if (result.logs && result.logs.length) {
            this.get("logs").pushObjects(result.logs.map((p) => Log.create(p)));
          } else {
            this.set("loadingComplete", true);
          }
        })
        .finally(() => this.set("loading", false));
    },
  },
});
