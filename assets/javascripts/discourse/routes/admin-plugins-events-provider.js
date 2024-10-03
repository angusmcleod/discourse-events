import { inject as service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";
import Provider from "../models/provider";

export default DiscourseRoute.extend({
  store: service(),

  model() {
    return Provider.all();
  },

  setupController(controller, model) {
    controller.setProperties({
      providers: Provider.toArray(this.store, model.providers),
    });
    controller.setMessage("info");
  },
});
