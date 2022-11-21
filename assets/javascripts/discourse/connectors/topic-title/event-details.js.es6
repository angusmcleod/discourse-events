export default {
  setupComponent(attrs, component) {
    const topic = attrs.model;
    let showRsvp =
      component.siteSettings.events_rsvp && topic.get("event.rsvp");

    component.set("showRsvp", showRsvp);

    topic.addObserver("event.rsvp", () => {
      if (this._state === "destroying") {
        return;
      }
      component.set(
        "showRsvp",
        component.siteSettings.events_rsvp && topic.get("event.rsvp")
      );
    });
  },
};
