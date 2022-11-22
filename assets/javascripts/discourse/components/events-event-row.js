import Component from "@ember/component";
import { observes } from "discourse-common/utils/decorators";

export default Component.extend({
  tagName: "tr",
  classNameBindings: [
    ":events-event-row",
    "showSelect",
    "selected",
  ],
  selected: false,

  @observes("showSelect")
  toggleWhenShowSelect() {
    if (!this.showSelect) {
      this.set("selected", false);
    }
  },

  @observes("selectAll")
  toggleWhenSelectAll() {
    this.set("selected", this.selectAll);
  },

  click() {
    if (this.showSelect) {
      this.selectEvent();
    }
  },

  selectEvent() {
    this.toggleProperty("selected");
    this.modifySelection([this.event], this.selected);
  },

  actions: {
    selectEvent() {
      this.selectEvent();
    },
  },
});
