export default {
  setupComponent(attrs, component) {
    if (!attrs.category.custom_fields) {
      attrs.category.custom_fields = {};
    }

    const siteEnabled = Discourse.SiteSettings.events_enabled;
    const categorySetting = attrs.category.custom_fields.events_enabled;
    let eventsEnabled = categorySetting !== undefined ? categorySetting : siteEnabled;
    component.set('eventsEnabled', eventsEnabled);

    component.addObserver('eventsEnabled', () => {
      if (this._state === 'destroying') return;
      attrs.category.custom_fields.events_enabled = component.get('eventsEnabled');
    })
  }
};
