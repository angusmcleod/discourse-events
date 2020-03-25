import { addEvent } from '../lib/date-utilities';

export default Ember.Controller.extend({
 
  actions: {
    hideModal(){
      const updatedEvent = addEvent(this.get('model.event'));
      this.get('model.update')(updatedEvent);
      this.send('closeModal');
    }
  }
});
