import Component from "@ember/component";
import { not, notEmpty } from "@ember/object/computed";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

const icons = {
  error: "times-circle",
  success: "check-circle",
  warn: "exclamation-circle",
  info: "circle-info",
};

const DOCUMENTATION_URL =
  "https://github.com/angusmcleod/discourse-events";

export default Component.extend({
  classNameBindings: [":events-message", "message.type", "loading"],
  showDocumentation: not("loading"),
  showIcon: not("loading"),
  hasItems: notEmpty("items"),

  @discourseComputed("message.type")
  icon(type) {
    return icons[type] || "circle-info";
  },

  @discourseComputed("message.key", "viewName", "message.opts")
  text(key, viewName, opts) {
    return I18n.t(`admin.events.message.${viewName}.${key}`, opts || {});
  },

  @discourseComputed
  documentation() {
    return I18n.t(`admin.events.message.documentation`);
  },

  @discourseComputed
  documentationUrl() {
    return DOCUMENTATION_URL;
  },
});
