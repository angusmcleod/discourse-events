import Component from "@ember/component";
import I18n from "I18n";
import discourseComputed from "discourse-common/utils/decorators";

export default Component.extend({
  classNames: ["events-header"],

  @discourseComputed("view")
  title(view) {
    return I18n.t(`admin.events.${view}.title`);
  },
});
