import Controller from "@ember/controller";
import { action } from "@ember/object";
import { not, notEmpty } from "@ember/object/computed";
import { service } from "@ember/service";
import I18n from "I18n";
import Message from "../mixins/message";
import Connection from "../models/connection";

export default Controller.extend(Message, {
  addDisabled: not("subscription.subscribed"),
  subscription: service("events-subscription"),
  hasConnections: notEmpty("connections"),
  dialog: service(),

  @action
  addConnection() {
    const connections = this.get("connections");
    if (!connections.isAny("id", "new")) {
      connections.unshiftObject(Connection.create({ id: "new" }));
    }
  },

  @action
  removeConnection(connection) {
    if (connection.id === "new") {
      this.get("connections").removeObject(connection);
    } else {
      this.dialog.confirm({
        message: I18n.t("admin.events.connection.remove.confirm"),
        confirmButtonLabel: "admin.events.connection.remove.label",
        cancelButtonLabel: "cancel",
        didConfirm: () => {
          Connection.destroy(connection).then(() => {
            this.get("connections").removeObject(connection);
          });
        },
      });
    }
  },
});
