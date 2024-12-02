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
  siteSettings: service(),

  didReceiveAttrs() {
    this._super();
    this.set("currentSource", JSON.parse(JSON.stringify(this.source)));
  },

  willDestroyElement() {
    this._super(...arguments);
    this.setMessage("info", "info");
  },

  @discourseComputed(
    "source.topic_sync",
    "source.provider_id",
    "source.import_type",
    "source.import_period",
    "source.source_options.@each",
    "source.user.username",
    "source.category_id",
    "source.client",
    "source.filters.[]",
    "source.filters.@each.query_column",
    "source.filters.@each.query_operator",
    "source.filters.@each.query_value"
  )
  sourceChanged(
    topicSync,
    providerId,
    importType,
    importPeriod,
    sourceOptions,
    username,
    categoryId,
    client,
    filters
  ) {
    const cs = this.currentSource;
    return (
      cs.topic_sync !== topicSync ||
      cs.provider_id !== providerId ||
      cs.import_period !== importPeriod ||
      !isEqual(cs.source_options, JSON.parse(JSON.stringify(sourceOptions))) ||
      !filtersMatch(filters, cs.filters) ||
      cs.import_type !== importType ||
      cs.user?.username !== username ||
      cs.category_id !== categoryId ||
      cs.client !== client
    );
  },

  @discourseComputed(
    "sourceChanged",
    "source.provider_id",
    "sourceOptions.@each.value"
  )
  saveDisabled(sourceChanged, providerId, sourceOptions) {
    return (
      !sourceChanged ||
      !providerId ||
      !sourceOptions ||
      sourceOptions.some((opt) => !opt.value)
    );
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
    "importing",
    "saving",
    "source.ready",
    "source.canImport",
    "source.import_type",
    "subscription.subscribed"
  )
  importDisabled(
    sourceChanged,
    sourceId,
    importing,
    saving,
    ready,
    canImport,
    importType
  ) {
    if (
      !this.subscription.supportsFeatureValue(
        "source",
        "import_type",
        importType
      )
    ) {
      return true;
    } else {
      return (
        sourceChanged ||
        sourceId === "new" ||
        importing ||
        saving ||
        !ready ||
        !canImport
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
  sourceOptions(source_options, providerSourceOptionFields) {
    if (!providerSourceOptionFields) {
      return [];
    }
    return providerSourceOptionFields.map((opt) => {
      return {
        name: opt.name,
        value: source_options[opt.name],
        type: opt.type,
      };
    });
  },

  @discourseComputed("provider.provider_type")
  allowedImportTypeValues(providerType) {
    if (providerType === "icalendar") {
      return ["import"];
    } else {
      return null;
    }
  },

  @discourseComputed("providers.@each.status")
  allowedProviderTypeValues(providers) {
    return providers
      .filter((p) => p.status === "ready")
      .map((p) => p.provider_type);
  },

  @discourseComputed(
    "siteSettings.calendar_enabled",
    "siteSettings.discourse_post_event_enabled"
  )
  allowedClientValues(calendarEnabled, postEventEnabled) {
    let allowedClients = ["discourse_events"];
    if (calendarEnabled && postEventEnabled) {
      allowedClients.push("discourse_calendar");
    }
    return allowedClients;
  },

  @discourseComputed(
    "sourceChanged",
    "saving",
    "syncing",
    "subscription.subscribed",
    "source.client",
    "source.topic_sync",
    "source.category_id",
    "source.user.username"
  )
  syncTopicsDisabled(
    sourceChanged,
    saving,
    syncing,
    subscribed,
    client,
    topicSync,
    categoryId,
    username
  ) {
    return (
      sourceChanged ||
      saving ||
      syncing ||
      !client ||
      !subscribed ||
      !this.subscription.supportsFeatureValue("source", "client", client) ||
      !topicSync ||
      !categoryId ||
      !username
    );
  },

  actions: {
    openFilters() {
      this.modal.show(EventsFilters, {
        model: this.get("source"),
      });
    },

    updateUser(usernames) {
      const source = this.source;
      if (!source.user) {
        source.set("user", {});
      }
      source.set("user.username", usernames[0]);
    },

    updateSourceOptions(name, event) {
      this.source.source_options.set(name, event.target.value);
    },

    updateProvider(providerType) {
      const provider = this.providers?.find(
        (p) => p.provider_type === providerType
      );
      this.set("source.provider_id", provider.id);
    },

    saveSource() {
      let source = JSON.parse(JSON.stringify(this.source));

      const supportedOptions = this.sourceOptionFields[
        this.provider.provider_type
      ].map((o) => o.name);

      source.source_options = Object.keys(source.source_options)
        .filter((name) => supportedOptions.includes(name))
        .reduce((obj, key) => {
          obj[key] = source.source_options[key];
          return obj;
        }, {});

      if (source.import_period === 0) {
        source.import_period = null;
      }

      if (source.user) {
        source.username = source.user.username;
        delete source.user;
      } else {
        source.username = null;
      }

      this.set("saving", true);

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
          this.set("saving", false);
        });
    },

    importSource() {
      this.set("importing", true);
      Source.importEvents(this.source)
        .then((result) => {
          if (result.success) {
            this.setMessage("event_import_started", "success");
          } else {
            this.setMessage("event_import_failed_to_start", "error");
          }
        })
        .finally(() => {
          this.set("importing", false);

          setTimeout(() => {
            if (!this.isDestroying && !this.isDestroyed) {
              this.setMessage("info", "info");
            }
          }, 5000);
        });
    },

    syncTopics() {
      const source = this.source;

      this.set("syncing", true);
      Source.syncTopics(source)
        .then((result) => {
          if (result.success) {
            this.setMessage("topic_creation_started", "success");
          } else {
            this.setMessage("topic_creation_failed_to_start", "error");
          }
        })
        .finally(() => {
          this.set("syncing", false);

          setTimeout(() => {
            if (!this.isDestroying && !this.isDestroyed) {
              this.setMessage("info", "info");
            }
          }, 5000);
        });
    },
  },
});
