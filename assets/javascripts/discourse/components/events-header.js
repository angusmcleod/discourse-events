import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend({
  classNames: ["events-header"],

  @discourseComputed("view")
  title(view) {
    return I18n.t(`admin.events.${view}.title`);
  },
});
