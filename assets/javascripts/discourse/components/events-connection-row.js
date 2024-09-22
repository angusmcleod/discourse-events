import Component from "@ember/component";
import { not, notEmpty, readOnly } from "@ember/object/computed";
import { service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import Connection from "../models/connection";
import { filtersMatch } from "../models/filter";
import EventsFilters from "./modal/events-filters";

export default Component.extend({
  tagName: "tr",
  attributeBindings: ["connection.id:data-connection-id"],
  classNameBindings: [
    ":events-connection-row",
    "hasChildCategory:has-child-category",
  ],
  hasFilters: notEmpty("connection.filters"),
  hasChildCategory: readOnly("connection.category.parent_category_id"),
  modal: service(),
  subscription: service("events-subscription"),
  removeDisabled: not("subscription.subscribed"),

  didReceiveAttrs() {
    this._super();
    this.set("currentConnection", JSON.parse(JSON.stringify(this.connection)));
  },

  @discourseComputed(
    "connection.user.username",
    "connection.category_id",
    "connection.source_id",
    "connection.auto_sync",
    "connection.client",
    "connection.filters.[]",
    "connection.filters.@each.query_column",
    "connection.filters.@each.query_operator",
    "connection.filters.@each.query_value"
  )
  connectionChanged(username, categoryId, sourceId, autoSync, client, filters) {
    const cc = this.currentConnection;
    return (
      (!cc.user && username) ||
      (cc.user && cc.user.username !== username) ||
      cc.category_id !== categoryId ||
      cc.source_id !== sourceId ||
      cc.auto_sync !== autoSync ||
      cc.client !== client ||
      !filtersMatch(filters, cc.filters)
    );
  },

  @discourseComputed(
    "connectionChanged",
    "connection.user.username",
    "connection.category_id",
    "connection.source_id",
    "connection.client"
  )
  saveDisabled(connectionChanged, username, categoryId, sourceId, client) {
    return (
      !connectionChanged || !username || !categoryId || !sourceId || !client
    );
  },

  @discourseComputed("connectionChanged")
  saveClass(connectionChanged) {
    return connectionChanged
      ? "btn-primary save-connection"
      : "save-connection";
  },

  @discourseComputed("syncDisabled")
  syncClass(syncDisabled) {
    return syncDisabled ? "sync-connection" : "btn-primary sync-connection";
  },

  @discourseComputed("connectionChanged", "loading", "connection.client")
  syncDisabled(connectionChanged, loading, connectionClient) {
    return (
      connectionChanged ||
      loading ||
      !this.subscription.supportsFeatureValue("connection", connectionClient)
    );
  },

  @discourseComputed
  syncOptions() {
    return [
      {
        id: true,
        name: I18n.t("admin.events.connection.sync_type.automatic"),
      },
      {
        id: false,
        name: I18n.t("admin.events.connection.sync_type.manual"),
      },
    ];
  },

  actions: {
    updateUser(usernames) {
      const connection = this.connection;
      if (!connection.user) {
        connection.set("user", {});
      }
      connection.set("user.username", usernames[0]);
    },

    openFilters() {
      this.modal.show(EventsFilters, {
        model: this.get("connection"),
      });
    },

    saveConnection() {
      const connection = this.connection;

      if (!connection.source_id) {
        return;
      }

      const data = {
        id: connection.id,
        category_id: connection.category_id,
        source_id: connection.source_id,
        auto_sync: connection.auto_sync,
        client: connection.client,
        user: connection.user,
      };

      if (connection.filters) {
        data.filters = JSON.parse(JSON.stringify(connection.filters));
      }

      this.set("loading", true);

      Connection.update(data)
        .then((result) => {
          if (result) {
            this.setProperties({
              currentConnection: result.connection,
              connection: Connection.create(result.connection),
            });
          } else if (this.currentSource.id !== "new") {
            this.set(
              "connection",
              JSON.parse(JSON.stringify(this.currentConnection))
            );
          }
        })
        .finally(() => {
          this.set("loading", false);
        });
    },

    syncConnection() {
      const connection = this.connection;

      this.set("loading", true);
      Connection.sync(connection)
        .then((result) => {
          if (result.success) {
            this.setMessage("sync_started", "success");
          } else {
            this.setMessage("sync_failed_to_start", "error");
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
