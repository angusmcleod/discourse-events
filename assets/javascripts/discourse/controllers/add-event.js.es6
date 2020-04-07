import { addEvent } from '../lib/date-utilities';
import ModalFunctionality from "discourse/mixins/modal-functionality";

export default Ember.Controller.extend(ModalFunctionality, {
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

      status ? this.clearFlash() : this.flash(I18n.t('add_event.error'), 'error');
    }
  }
});
