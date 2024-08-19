import { getOwner } from "@ember/application";
import Category from "discourse/models/category";

export default {
  shouldRender(_, ctx) {
    return ctx.siteSettings.events_enabled;
  },

  setupComponent(_, component) {
    const buffered = this.get("buffered");
    const user = component.currentUser;
    const showEventControls = (category) => {
      return (
        category &&
        category.events_enabled &&
        (user.staff || user.trust_level >= category.events_min_trust_to_create)
      );
    };
    component.set(
      "showEventControls",
      showEventControls(buffered.get("category"))
    );
    buffered.addObserver("category_id", () => {
      if (this._state === "destroying") {
        return;
      }
      let category = Category.findById(this.get("buffered.category_id"));
      component.set("showEventControls", showEventControls(category));
    });
  },

  actions: {
    updateEvent(event) {
      const controller = getOwner(this).lookup("controller:topic");
      controller.set("buffered.event", event);
    },
  },
};
