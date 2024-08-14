import DiscourseRoute from "discourse/routes/discourse";
import Event from "../models/event";

export default DiscourseRoute.extend({
  queryParams: {
    order: { refreshModel: true },
    asc: { refreshModel: true },
  },

  model(params) {
    let page = params.page || 0;
    let order = params.order || "start_time";
    let asc = params.asc || false;
    return Event.list({ page, order, asc });
  },

  setupController(controller, model) {
    controller.setProperties({
      page: model.page,
      events: Event.eventsArray(model.events),
    });
  },
});
