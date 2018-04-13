import showModal from 'discourse/lib/show-modal';
import { eventLabel } from '../lib/date-utilities';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: ['event-label'],

  didInsertElement() {
    if (this.site.isMobileDevice) {
      const $controls = this.$();
      $controls.detach();
      $controls.insertAfter($('#reply-control .title-input input'));
    }
  },

  @computed()
  valueClasses() {
    let classes = "add-event";
    if (this.site.isMobileDevice) classes += " btn-primary";
    return classes;
  },

  @computed('event')
  valueLabel(event) {
    return eventLabel(event, {
      mobile: this.site.isMobileDevice,
      displayInTimezone: false
    });
  },

  @computed()
  addLabel() {
    const icon = Discourse.SiteSettings.events_event_label_icon;
    const iconHtml = `<i class='fa fa-${icon}'></i>`;
    return this.site.isMobileDevice ? iconHtml : I18n.t('add_event.btn_label', { iconHtml });
  },

  @computed('category')
  iconOnly(category) {
    return this.site.mobileView ||
           Discourse.SiteSettings.events_event_label_no_text ||
           category && category.get('events_event_label_no_text');
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
