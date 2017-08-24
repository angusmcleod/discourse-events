import showModal from 'discourse/lib/show-modal';
import { eventLabel } from '../lib/date-utilities';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: ['event-label'],

  actions: {
    showAddEvent() {
      let controller = showModal('set-event', {
        model: {
          event: this.get('event'),
          update: (event) => {
            this.set('event', event)
          }
        }
      });

      controller.send('setup');
    },

    removeEvent() {
      this.set('event', null);
    }
  }
})
