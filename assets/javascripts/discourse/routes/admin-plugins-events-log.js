import { A } from "@ember/array";
import DiscourseRoute from "discourse/routes/discourse";
import Log from "../models/log";

export default DiscourseRoute.extend({
  queryParams: {
    order: { refreshModel: true },
    asc: { refreshModel: true },
  },

  model(params) {
    let page = params.page || 0;
    let order = params.order || "created_at";
    let asc = params.asc || false;
    return Log.list({ page, order, asc });
  },

  setupController(controller, model) {
    controller.setProperties({
      page: model.page,
      logs: A(model.logs.map((p) => Log.create(p))),
      loadingComplete: false,
      loading: false,
    });
    controller.setMessage("info");
  },
});
