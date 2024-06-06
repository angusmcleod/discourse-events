import Component from "@ember/component";
import Connection from "../models/connection";
import discourseComputed from "discourse-common/utils/decorators";
import { notEmpty, readOnly } from "@ember/object/computed";
import { service } from "@ember/service";
import EventsConnectionFilters from "./modal/events-connection-filters";

function filtersMatch(filters1, filters2) {
  if ((filters1 && !filters2) || (!filters1 && filters2)) {
    return false;
  }

  if (!filters1 && !filters2) {
    return true;
  }

  if (filters1.length !== filters2.length) {
    return false;
  }

  return filters1.every((f1) =>
    filters2.some((f2) => {
      return (
        f2.query_column === f1.query_column && f2.query_value === f1.query_value
      );
    })
  );
}

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

  didReceiveAttrs() {
    this.set("currentConnection", JSON.parse(JSON.stringify(this.connection)));
  },

  willDestroyElement() {
    this._super(...arguments);
    this.setMessage("info", "info");
  },

  @discourseComputed(
    "connection.user.username",
    "connection.category_id",
    "connection.source_id",
    "connection.client",
    "connection.from_time",
    "connection.to_time",
    "connection.filters.[]",
    "connection.filters.@each.query_column",
    "connection.filters.@each.query_value"
  )
  connectionChanged(
    username,
    categoryId,
    sourceId,
    client,
    fromTime,
    toTime,
    filters
  ) {
    const cc = this.currentConnection;
    return (
      (!cc.user && username) ||
      (cc.user && cc.user.username !== username) ||
      cc.category_id !== categoryId ||
      cc.source_id !== sourceId ||
      cc.client !== client ||
      cc.from_time !== fromTime ||
      cc.to_time !== toTime ||
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

  @discourseComputed("connectionChanged", "loading")
  syncDisabled(connectionChanged, loading) {
    return connectionChanged || loading;
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
    updateUser(usernames) {
      const connection = this.connection;
      if (!connection.user) {
        connection.set("user", {});
      }
      connection.set("user.username", usernames[0]);
    },

    openFilters() {
      this.modal.show(EventsConnectionFilters, {
        model: {
          connection: this.get("connection"),
        },
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
        client: connection.client,
        source_id: connection.source_id,
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
