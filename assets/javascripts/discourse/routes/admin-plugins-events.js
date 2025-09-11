import DiscourseRoute from "discourse/routes/discourse";
import { service } from "@ember/service";

export default DiscourseRoute.extend({
  router: service(),

  afterModel(model, transition) {
    if (transition.to.name === "adminPlugins.events.index") {
      this.router.transitionTo("adminPlugins.events.event");
    }
  },

  actions: {
    showSettings() {
      const controller = this.controllerFor("adminSiteSettings");
      this.router
        .transitionTo("adminSiteSettingsCategory", "plugins")
        .then(() => {
          controller.set("filter", "plugin:discourse-events");
          controller.set("_skipBounce", true);
          controller.filterContentNow("plugins");
        });
    },
  },
});
