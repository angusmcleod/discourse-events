import { inject as service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";
import Event from "../models/event";

export default DiscourseRoute.extend({
  router: service(),

  queryParams: {
    order: { refreshModel: true },
    asc: { refreshModel: true },
    filter: { refreshModel: true },
  },

  model(params) {
    let page = params.page || 0;
    let order = params.order || "start_time";
    let asc = params.asc || false;
    let filter = params.filter || "connected";
    return Event.list({ page, order, asc, filter });
  },

  setupController(controller, model) {
    controller.setProperties({
      page: model.page,
      filter: model.filter,
      order: model.order,
      events: Event.eventsArray(model.events),
      withTopicsCount: model.with_topics_count,
      withoutTopicsCount: model.without_topics_count,
    });
  },
});
