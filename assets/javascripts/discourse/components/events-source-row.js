import { A } from "@ember/array";
import Component from "@ember/component";
import { empty, not, notEmpty } from "@ember/object/computed";
import { service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import Filter, { filtersMatch } from "../models/filter";
import Source from "../models/source";
import SourceOptions from "../models/source-options";
import EventsFilters from "./modal/events-filters";

const isEqual = function (obj1, obj2) {
  return JSON.stringify(obj1) === JSON.stringify(obj2);
};

export default Component.extend({
  tagName: "tr",
  classNames: ["events-source-row"],
  attributeBindings: ["source.id:data-source-id"],
  hasFilters: notEmpty("source.filters"),
  modal: service(),
  subscription: service("events-subscription"),
  removeDisabled: not("subscription.subscribed"),

  didReceiveAttrs() {
    this._super();
    this.set("currentSource", JSON.parse(JSON.stringify(this.source)));
  },

  willDestroyElement() {
    this._super(...arguments);
    this.setMessage("info", "info");
  },

  @discourseComputed(
    "source.name",
    "source.provider_id",
    "source.sync_type",
    "source.import_period",
    "source.source_options.@each",
    "source.filters.[]",
    "source.filters.@each.query_column",
    "source.filters.@each.query_operator",
    "source.filters.@each.query_value"
  )
  sourceChanged(
    sourceName,
    providerId,
    syncType,
    importPeriod,
    sourceOptions,
    filters
  ) {
    const cs = this.currentSource;
    return (
      cs.name !== sourceName ||
      cs.provider_id !== providerId ||
      cs.import_period !== importPeriod ||
      !isEqual(cs.source_options, JSON.parse(JSON.stringify(sourceOptions))) ||
      !filtersMatch(filters, cs.filters) ||
      cs.sync_type !== syncType
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

  @discourseComputed(
    "sourceChanged",
    "source.id",
    "loading",
    "source.ready",
    "source.canImport",
    "source.sync_type"
  )
  importDisabled(sourceChanged, sourceId, loading, ready, canImport, syncType) {
    if (!this.subscription.supportsFeatureValue("source", syncType)) {
      return true;
    } else {
      return (
        sourceChanged || sourceId === "new" || loading || !ready || !canImport
      );
    }
  },

  importPeriodDisabled: not("source.canImport"),

  @discourseComputed("source.provider_id")
  provider(providerId) {
    return this.providers?.find((p) => p.id === providerId);
  },

  @discourseComputed("sourceOptionFields", "provider.provider_type")
  providerSourceOptionFields(sourceOptionFields, providerType) {
    if (sourceOptionFields) {
      return sourceOptionFields[providerType];
    } else {
      return [];
    }
  },

  sourceOptionsDisabled: empty("sourceOptionFields"),

  @discourseComputed(
    "source.source_options.@each",
    "providerSourceOptionFields.@each"
  )
  sourceOptions(source_options) {
    return this.providerSourceOptionFields.map((opt) => {
      return {
        name: opt.name,
        value: source_options[opt.name],
        type: opt.type,
      };
    });
  },

  actions: {
    openFilters() {
      this.modal.show(EventsFilters, {
        model: this.get("source"),
      });
    },

    updateSourceOptions(name, event) {
      this.source.source_options.set(name, event.target.value);
    },

    updateProvider(provider_id) {
      this.set("source.provider_id", provider_id);
    },

    saveSource() {
      let source = JSON.parse(JSON.stringify(this.source));

      if (!source.name) {
        return;
      }

      const supportedOptions = this.sourceOptionFields[
        this.provider.provider_type
      ].map((o) => o.name);

      source.source_options = Object.keys(source.source_options)
        .filter((name) => supportedOptions.includes(name))
        .reduce((obj, key) => {
          obj[key] = source.source_options[key];
          return obj;
        }, {});

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
