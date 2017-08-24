import { observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: ['composer-add-event'],

  didInsertElement() {
    this.sendAction('updateTip', 'composer.tip.add_event', 'top');
  },

  @observes('event', 'location')
  checkIfReady() {
    const event = this.get('event');
    const location = this.get('location');
    if (event && location) {
      this.sendAction('addComposerProperty', 'event', event);
      this.sendAction('addComposerProperty', 'location', location);
      this.sendAction('ready');
    }
  }
})
