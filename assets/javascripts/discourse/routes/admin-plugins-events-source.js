import { A } from "@ember/array";
import DiscourseRoute from "discourse/routes/discourse";
import Provider from "../models/provider";
import Source from "../models/source";
import SourceOptions from "../models/source-options";

export default DiscourseRoute.extend({
  model() {
    return Source.all();
  },

  setupController(controller, model) {
    controller.setProperties({
      sources: A(
        model.sources.map((s) => {
          s.source_options = SourceOptions.create(s.source_options);
          return Source.create(s);
        })
      ),
      providers: A(model.providers.map((p) => Provider.create(p))),
    });
  },
});
