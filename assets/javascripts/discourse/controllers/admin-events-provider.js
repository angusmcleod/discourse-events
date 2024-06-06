import Controller from "@ember/controller";
import { notEmpty } from "@ember/object/computed";
import { service } from "@ember/service";
import I18n from "I18n";
import Message from "../mixins/message";
import Provider from "../models/provider";

export default Controller.extend(Message, {
  hasProviders: notEmpty("providers"),
  viewName: "provider",
  dialog: service(),

  actions: {
    addProvider() {
      this.get("providers").pushObject(
        Provider.create({
          id: "new",
        })
      );
    },

    removeProvider(provider) {
      if (provider.id === "new") {
        this.get("providers").removeObject(provider);
      } else {
        this.dialog.confirm({
          message: I18n.t("admin.events.provider.remove.confirm", {
            provider_name: provider.name,
          }),
          confirmButtonLabel: "admin.events.provider.remove.label",
          cancelButtonLabel: "cancel",
          didConfirm: () => {
            Provider.destroy(provider).then(() => {
              this.get("providers").removeObject(provider);
            });
          },
        });
      }
    },
  },
});
