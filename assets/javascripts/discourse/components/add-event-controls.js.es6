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
    return this.site.isMobileDevice ? '' : eventLabel(event);
  },

  @computed()
  addLabel() {
    return this.site.isMobileDevice ? '' : 'add_event.btn_label';
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
})
