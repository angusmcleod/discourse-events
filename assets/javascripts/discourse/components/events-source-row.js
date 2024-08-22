import { A } from "@ember/array";
import Component from "@ember/component";
import { notEmpty } from "@ember/object/computed";
import { service } from "@ember/service";
import discourseComputed, { observes } from "discourse-common/utils/decorators";
import Filter, { filtersMatch } from "../models/filter";
import Source from "../models/source";
import SourceOptions from "../models/source-options";
import EventsFilters from "./modal/events-filters";

const isEqual = function (obj1, obj2) {
  return JSON.stringify(obj1) === JSON.stringify(obj2);
};

const SOURCE_OPTIONS = {
  icalendar: [
    {
      name: "uri",
      type: "text",
      default: "",
    },
  ],
  eventbrite: [
    {
      name: "organization_id",
      type: "number",
      default: null,
    },
  ],
  humanitix: [],
  eventzilla: [],
  meetup: [
    {
      name: "group_urlname",
      type: "text",
      default: "",
    },
  ],
  outlook: [
    {
      name: "user_id",
      type: "text",
      defualt: "",
    },
    {
      name: "calendar_id",
      type: "text",
      default: "",
    },
  ],
};

export default Component.extend({
  tagName: "tr",
  classNames: ["events-source-row"],
  attributeBindings: ["source.id:data-source-id"],
  SourceOptions: [],
  hasFilters: notEmpty("source.filters"),
  modal: service(),

  didReceiveAttrs() {
    this._super();
    this.set("currentSource", JSON.parse(JSON.stringify(this.source)));
    this.setSourceOptions();
  },

  willDestroyElement() {
    this._super(...arguments);
    this.setMessage("info", "info");
  },

  @discourseComputed(
    "source.name",
    "source.provider_id",
    "source.source_options.@each",
    "source.filters.[]",
    "source.filters.@each.query_column",
    "source.filters.@each.query_operator",
    "source.filters.@each.query_value"
  )
  sourceChanged(sourceName, providerId, sourceOptions, filters) {
    const cs = this.currentSource;
    return (
      cs.name !== sourceName ||
      cs.provider_id !== providerId ||
      !isEqual(cs.source_options, JSON.parse(JSON.stringify(sourceOptions))) ||
      !filtersMatch(filters, cs.filters)
    );
  },

  @discourseComputed(
    "sourceChanged",
    "source.name",
    "source.provider_id",
    "source.source_options.@each"
  )
  saveDisabled(sourceChanged, name, providerId, sourceOptions) {
    return !sourceChanged || !name || !providerId || !sourceOptions;
  },

  @discourseComputed("sourceChanged")
  saveClass(sourceChanged) {
    return sourceChanged ? "btn-primary save-source" : "save-source";
  },

  @discourseComputed("importDisabled")
  importClass(importDisabled) {
    return importDisabled ? "import-source" : "btn-primary import-source";
  },

  @discourseComputed("sourceChanged", "source.id", "loading")
  importDisabled(sourceChanged, sourceId, loading) {
    return sourceChanged || sourceId === "new" || loading;
  },

  @discourseComputed("source.source_options.@each")
  sourceOptionsMap(source_options) {
    return this.sourceOptions.map((opt) => {
      return {
        name: opt.name,
        value: source_options[opt.name],
        type: opt.type,
      };
    });
  },

  resetProvider() {
    this.get("source").setProperties({
      provider_id: null,
      source_options: SourceOptions.create(),
    });
    this.set("sourceOptions", []);
  },

  @observes("source.provider_id")
  setSourceOptions() {
    const providerId = this.source.provider_id;
    const providers = this.providers;
    const provider = providers.find((p) => p.id === providerId);

    if (!providers || !provider) {
      this.resetProvider();
      return;
    }

    const sourceOptions = SOURCE_OPTIONS[provider.provider_type];
    const currentSourceOptions = this.currentSource.source_options || {};
    const source_options = {};

    sourceOptions.forEach((opt) => {
      source_options[opt.name] = currentSourceOptions[opt.name] || opt.default;
    });

    this.set("source.source_options", SourceOptions.create(source_options));
    this.set("sourceOptions", sourceOptions);
  },

  @discourseComputed("hasFilters")
  filterClass(hasFilters) {
    let classes = "show-filters";
    if (hasFilters) {
      classes += " btn-primary";
    }
    return classes;
  },

  actions: {
    openFilters() {
      this.modal.show(EventsFilters, {
        model: this.get("source"),
      });
    },

    updateProvider(provider_id) {
      this.set("source.provider_id", provider_id);
    },

    updateSourceOptions(source_options, name, event) {
      source_options.set(name, event.target.value);
    },

    saveSource() {
      const source = JSON.parse(JSON.stringify(this.source));

      if (!source.name) {
        return;
      }

      this.set("loading", true);

      Source.update(source)
        .then((result) => {
          if (result) {
            let source_params = Object.assign(result.source, {
              source_options: SourceOptions.create(
                result.source.source_options
              ),
            });
            if (result.source.filters) {
              source_params.filters = A(
                result.source.filters.map((f) => {
                  return Filter.create(f);
                })
              );
            }
            this.setProperties({
              currentSource: result.source,
              source: Source.create(source_params),
            });
          } else if (this.currentSource.id !== "new") {
            this.set("source", JSON.parse(JSON.stringify(this.currentSource)));
          }
        })
        .finally(() => {
          this.set("loading", false);
        });
    },

    importSource() {
      this.set("loading", true);
      Source.import(this.source)
        .then((result) => {
          if (result.success) {
            this.setMessage("import_started", "success");
          } else {
            this.setMessage("import_failed_to_start", "error");
          }
        })
        .finally(() => {
          this.set("loading", false);

          setTimeout(() => {
            if (!this.isDestroying && !this.isDestroyed) {
              this.setMessage("info", "info");
            }
          }, 5000);
        });
    },
  },
});
