import { getOwner } from "@ember/application";

export default {
  shouldRender(_, ctx) {
    return ctx.siteSettings.events_enabled;
  },

  setupComponent(_, component) {
    const controller = getOwner(this).lookup("controller:composer");
    component.set("eventValidation", controller.get("eventValidation"));
    controller.addObserver("eventValidation", () => {
      if (this._state === "destroying") {
        return;
      }
      component.set("eventValidation", controller.get("eventValidation"));
    });
  },

  actions: {
    updateEvent(event) {
      const controller = getOwner(this).lookup("controller:composer");
      controller.set("model.event", event);
    },
  },
};
