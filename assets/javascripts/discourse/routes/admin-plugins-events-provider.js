import { A } from "@ember/array";
import DiscourseRoute from "discourse/routes/discourse";
import Provider from "../models/provider";

export default DiscourseRoute.extend({
  model() {
    return Provider.all();
  },

  setupController(controller, model) {
    controller.setProperties({
      providers: A(model.providers.map((p) => Provider.create(p))),
    });
  },
});
