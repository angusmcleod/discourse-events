import { addEvent } from '../lib/date-utilities';

export default Ember.Controller.extend({
  title: 'add_event.modal_title',
  
  actions: {
    clear() {
      this.set('bufferedEvent', null);
    },
    
    saveEvent(){
      this.get('model.update')(this.bufferedEvent);
      this.send('closeModal');
    },
    
    updateEvent(event, status) {
      this.set('bufferedEvent', event);
      this.set('notReady', !status);
    }
  }
});
