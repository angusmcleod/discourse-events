import Component from "@ember/component";
import { observes } from "discourse-common/utils/decorators";

export default Component.extend({
  tagName: "tr",
  classNameBindings: [":events-event-row", "selected"],
  selected: false,

  @observes("selectAll")
  toggleWhenSelectAll() {
    this.set("selected", this.selectAll);
  },

  @observes("selected")
  selectEvent() {
    this.modifySelection([this.event], this.selected);
  },
});
