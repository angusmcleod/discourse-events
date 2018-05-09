export default {
  setupComponent(attrs, component) {
    const topic = attrs.model;
    let showRsvp = Discourse.SiteSettings.events_rsvp && topic.get('event.rsvp');

    component.set('showRsvp', showRsvp);

    topic.addObserver('event.rsvp', () => {
      if (this._state === 'destroying') return;
      component.set('showRsvp', Discourse.SiteSettings.events_rsvp && topic.get('event.rsvp'));
    })
  }
}
