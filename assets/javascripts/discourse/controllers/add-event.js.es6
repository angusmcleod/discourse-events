import { addEvent } from '../lib/date-utilities';

export default Ember.Controller.extend({
  actions: {
    clear() {
      this.set('model.event', null);
      this.get('model.update')(null);
    },
    saveEvent(){
      if(this.get('model.event')) {
        const updatedEvent = addEvent(this.get('model.event'));
        this.get('model.update')(updatedEvent);
      }

      this.send('closeModal');
    },
    validateEvent(status) {
      this.set('notReady', !status);
    }
  }
});
