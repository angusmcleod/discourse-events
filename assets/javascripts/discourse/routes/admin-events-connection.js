import DiscourseRoute from "discourse/routes/discourse";
import Connection from "../models/connection";
import ConnectionFilter from "../models/connection-filter";
import Source from "../models/source";
import { A } from "@ember/array";
import { contentsMap } from "../lib/events";

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
                return ConnectionFilter.create(f);
              })
            );
          }
          return Connection.create(c);
        })
      ),
      sources: A(model.sources.map((s) => Source.create(s))),
      clients: contentsMap(model.clients),
    });
  },
});
