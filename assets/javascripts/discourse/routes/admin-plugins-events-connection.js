import { A } from "@ember/array";
import DiscourseRoute from "discourse/routes/discourse";
import Connection from "../models/connection";
import Filter from "../models/filter";
import Source from "../models/source";

export default DiscourseRoute.extend({
  model() {
    return Connection.all();
  },

  setupController(controller, model) {
    controller.setProperties({
      connections: A(
        model.connections.map((c) => {
          if (c.filters) {
            c.filters = A(
              c.filters.map((f) => {
                return Filter.create(f);
              })
            );
          }
          return Connection.create(c);
        })
      ),
      sources: A(model.sources.map((s) => Source.create(s))),
    });
    controller.setMessage("info");
  },
});
