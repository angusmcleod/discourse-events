import Controller from "@ember/controller";
import Provider from "../models/provider";
import { notEmpty } from "@ember/object/computed";
import Message from "../mixins/message";
import I18n from "I18n";

export default Controller.extend(Message, {
  hasProviders: notEmpty("providers"),
  view: "provider",

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
        bootbox.confirm(
          I18n.t("admin.events.provider.remove.confirm", {
            provider_name: provider.name,
          }),
          I18n.t("cancel"),
          I18n.t("admin.events.provider.remove.label"),
          (result) => {
            if (result) {
              Provider.destroy(provider).then(() => {
                this.get("providers").removeObject(provider);
              });
            }
          }
        );
      }
    },
  },
});
