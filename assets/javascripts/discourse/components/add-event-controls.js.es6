import showModal from 'discourse/lib/show-modal';
import { eventLabel } from '../lib/date-utilities';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: ['event-label'],

  didInsertElement() {
    $('.title-and-category').toggleClass('event-add-no-text', this.get("iconOnly"));
  },

  @computed('noText')
  valueClasses(noText) {
    let classes = "add-event";
    if (noText) classes += " btn-primary";
    return classes;
  },

  @computed('event')
  valueLabel(event) {
    return eventLabel(event, {
      noText: this.get('noText'),
      useEventTimezone: true,
      showRsvp: true
    });
  },

  @computed('category', 'noText')
  iconOnly(category, noText) {
    return noText ||
           Discourse.SiteSettings.events_event_label_no_text ||
           Boolean(category && category.get('custom_fields.events_event_label_no_text'));
  },

  actions: {
    showAddEvent() {
      let controller = showModal('add-event', {
        model: {
          event: this.get('event'),
          update: (event) => this.set('event', event)
        }
      });

      controller.setup();
    },

    removeEvent() {
      this.set('event', null);
    }
  }
});
