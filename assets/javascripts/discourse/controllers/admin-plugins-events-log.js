import Controller from "@ember/controller";
import { action } from "@ember/object";
import { notEmpty } from "@ember/object/computed";
import Message from "../mixins/message";
import Log from "../models/log";

export default class AdminPluginsEventsLog extends Controller.extend(Message) {
  @notEmpty("logs") hasLogs;
  queryParams = ["order", "asc"];
  order = "";
  asc = null;
  viewName = "log";
  loading = false;
  loadingComplete = false;
  page = 0;

  @action
  loadMore() {
    if (this.loading || this.loadingComplete) {
      return;
    }

    let page = this.page + 1;
    this.page = page;
    this.loading = true;

    let params = {
      page,
    };
    if (this.asc) {
      params.asc = this.asc;
    }
    if (this.order) {
      params.order = this.order;
    }

    Log.list(params)
      .then((result) => {
        if (result?.logs && result.logs.length) {
          this.logs.pushObjects(result.logs.map((p) => Log.create(p)));
        } else {
          this.loadingComplete = true;
        }
      })
      .finally(() => {
        this.loading = false;
      });
  }

  @action
  updateOrder(field, asc) {
    this.setProperties({
      order: field,
      asc,
    });
  }
}
