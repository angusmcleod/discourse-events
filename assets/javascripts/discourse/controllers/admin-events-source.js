import Controller from "@ember/controller";
import Source from "../models/source";
import SourceOptions from "../models/source-options";
import { notEmpty } from "@ember/object/computed";
import Message from "../mixins/message";
import I18n from "I18n";
import { service } from "@ember/service";

export default Controller.extend(Message, {
  hasSources: notEmpty("sources"),
  view: "source",
  dialog: service(),

  actions: {
    addSource() {
      this.get("sources").pushObject(
        Source.create({
          id: "new",
          source_options: SourceOptions.create(),
          from_time: moment()
            .subtract(1, "months")
            .add(30, "minutes")
            .startOf("hour"),
          to_time: moment().add(5, "months").add(30, "minutes").startOf("hour"),
        })
      );
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
