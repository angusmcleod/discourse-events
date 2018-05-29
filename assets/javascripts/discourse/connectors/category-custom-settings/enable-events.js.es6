export default {
  setupComponent(attrs, component) {
    if (!attrs.category.custom_fields) {
      attrs.category.custom_fields = {};
    }

    const settingValueToggle = function(name) {
      const settings = Discourse.SiteSettings;
      const siteEnabled = settings[name];
      const categorySetting = attrs.category.custom_fields[name];
      const property = name.camelize();
      const value = categorySetting !== undefined ? categorySetting : siteEnabled;

      component.set(property, value);

      component.addObserver(property, function() {
        if (this._state === 'destroying') return;
        attrs.category.custom_fields[name] = component.get(property);
      })
    }

    settingValueToggle('events_enabled');
    settingValueToggle('events_agenda_enabled');
    settingValueToggle('events_calendar_enabled');
    settingValueToggle('events_event_label_no_text');
    settingValueToggle('events_required');
  }
};
