import { A } from "@ember/array";
import DiscourseRoute from "discourse/routes/discourse";
import I18n from "I18n";
import Filter from "../models/filter";
import Provider from "../models/provider";
import Source from "../models/source";
import SourceOptions from "../models/source-options";

export default DiscourseRoute.extend({
  model() {
    return Source.all();
  },

  setupController(controller, model) {
    const importPeriods = [];
    Object.keys(model.import_periods).forEach((period) => {
      importPeriods.push({
        id: model.import_periods[period],
        name: I18n.t(`admin.events.source.import_period.${period}`),
      });
    });

    controller.setProperties({
      sources: A(
        model.sources.map((s) => {
          s.source_options = SourceOptions.create(s.source_options);
          if (s.filters) {
            s.filters = A(
              s.filters.map((f) => {
                return Filter.create(f);
              })
            );
          }
          return Source.create(s);
        })
      ),
      providers: A(model.providers.map((p) => Provider.create(p))),
      importPeriods,
      sourceOptionFields: model.source_options,
    });
    controller.setMessage("info");
  },
});
