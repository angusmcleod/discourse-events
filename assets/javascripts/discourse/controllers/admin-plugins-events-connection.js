import Controller from "@ember/controller";
import { not, notEmpty } from "@ember/object/computed";
import { service } from "@ember/service";
import I18n from "I18n";
import Message from "../mixins/message";
import Connection from "../models/connection";

export default Controller.extend(Message, {
  hasConnections: notEmpty("connections"),
  viewName: "connection",
  dialog: service(),
  subscription: service("events-subscription"),
  addDisabled: not("subscription.subscribed"),

  actions: {
    addConnection() {
      this.get("connections").pushObject(
        Connection.create({
          id: "new",
          from_time: moment()
            .subtract(1, "months")
            .add(30, "minutes")
            .startOf("hour"),
          to_time: moment().add(5, "months").add(30, "minutes").startOf("hour"),
        })
      );
    },

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
  },
});
