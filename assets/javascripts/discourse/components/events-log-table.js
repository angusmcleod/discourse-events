import Component from "@glimmer/component";
import { action } from "@ember/object";
import Log from "../models/log";

export default class EventsLogTable extends Component {
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

    Log.list({ page })
      .then((result) => {
        if (result.logs && result.logs.length) {
          this.args.logs.pushObjects(result.logs.map((p) => Log.create(p)));
        } else {
          this.loadingComplete = true;
        }
      })
      .finally(() => {
        this.loading = false;
      });
  }
}
