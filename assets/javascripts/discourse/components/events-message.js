import discourseComputed from "discourse-common/utils/decorators";
import { not, notEmpty } from "@ember/object/computed";
import Component from "@ember/component";
import I18n from "I18n";

const icons = {
  error: "times-circle",
  success: "check-circle",
  warn: "exclamation-circle",
  info: "info-circle",
};

const urls = {
  provider: "https://coop.pavilion.tech/t/1220",
  source: "https://coop.pavilion.tech/t/1221",
  connection: "https://coop.pavilion.tech/t/1222",
  event: "https://coop.pavilion.tech/t/1223",
  log: "https://coop.pavilion.tech/t/1223",
};

export default Component.extend({
  classNameBindings: [":events-message", "message.type", "loading"],
  showDocumentation: not("loading"),
  showIcon: not("loading"),
  hasItems: notEmpty("items"),

  @discourseComputed("message.type")
  icon(type) {
    return icons[type] || "info-circle";
  },

  @discourseComputed("message.key", "view", "message.opts")
  text(key, view, opts) {
    return I18n.t(`admin.events.message.${view}.${key}`, opts || {});
  },

  @discourseComputed
  documentation() {
    return I18n.t(`admin.events.message.documentation`);
  },

  @discourseComputed("view")
  documentationUrl(view) {
    return urls[view] || "https://coop.pavilion.tech/c/discourse-events";
  },
});
