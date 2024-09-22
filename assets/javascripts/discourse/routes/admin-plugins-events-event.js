import DiscourseRoute from "discourse/routes/discourse";
import Event from "../models/event";

export default DiscourseRoute.extend({
  queryParams: {
    order: { refreshModel: true },
    asc: { refreshModel: true },
    filter: { refreshModel: true },
  },

  model(params) {
    let page = params.page || 0;
    let order = params.order || "start_time";
    let asc = params.asc || false;
    let filter = params.filter || "topics";
    return Event.list({ page, order, asc, filter });
  },

  setupController(controller, model) {
    controller.setProperties({
      page: model.page,
      events: Event.eventsArray(model.events),
    });
    const filter = this.paramsFor("adminPlugins.events.event").filter;
    controller.setMessage(`${filter || "topics"}.info`);
  },
});
