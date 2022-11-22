import Controller from "@ember/controller";
import Connection from "../models/connection";
import { notEmpty } from "@ember/object/computed";
import Message from "../mixins/message";
import I18n from "I18n";

export default Controller.extend(Message, {
  hasConnections: notEmpty("connections"),
  view: "connection",

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
        bootbox.confirm(
          I18n.t("admin.events.connection.remove.confirm"),
          I18n.t("cancel"),
          I18n.t("admin.events.connection.remove.label"),
          (result) => {
            if (result) {
              Connection.destroy(connection).then(() => {
                this.get("connections").removeObject(connection);
              });
            }
          }
        );
      }
    },
  },
});
