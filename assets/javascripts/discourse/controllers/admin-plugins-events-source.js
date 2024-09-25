import Controller from "@ember/controller";
import { not, notEmpty } from "@ember/object/computed";
import { service } from "@ember/service";
import I18n from "I18n";
import Message from "../mixins/message";
import Source from "../models/source";
import SourceOptions from "../models/source-options";

export default Controller.extend(Message, {
  hasSources: notEmpty("sources"),
  viewName: "source",
  dialog: service(),
  subscription: service("events-subscription"),
  addDisabled: not("subscription.subscribed"),
  router: service(),

  actions: {
    addSource() {
      const sources = this.get("sources");
      if (!sources.isAny("id", "new")) {
        sources.unshiftObject(
          Source.create({
            id: "new",
            source_options: SourceOptions.create(),
          })
        );
      }
    },

    removeSource(source) {
      if (source.id === "new") {
        this.get("sources").removeObject(source);
      } else {
        this.dialog.confirm({
          message: I18n.t("admin.events.source.remove.confirm", {
            source_name: source.name,
          }),
          confirmButtonLabel: "admin.events.source.remove.label",
          cancelButtonLabel: "cancel",
          didConfirm: () => {
            Source.destroy(source).then(() => {
              this.get("sources").removeObject(source);
            });
          },
        });
      }
    },
  },
});
