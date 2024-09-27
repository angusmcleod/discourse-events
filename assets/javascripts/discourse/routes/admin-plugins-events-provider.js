import DiscourseRoute from "discourse/routes/discourse";
import Provider from "../models/provider";

export default DiscourseRoute.extend({
  model() {
    return Provider.all();
  },

  setupController(controller, model) {
    controller.setProperties({
      providers: Provider.toArray(model.providers),
    });
    controller.setMessage("info");
  },
});
