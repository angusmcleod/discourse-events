import { addEvent } from '../lib/date-utilities';
import ModalFunctionality from "discourse/mixins/modal-functionality";
import Controller from "@ember/controller";

export default Controller.extend(ModalFunctionality, {
  title: 'add_event.modal_title',
  
  actions: {
    clear() {
      this.set('bufferedEvent', null);
    },
    
    saveEvent(){
      if (this.valid) {
        this.get('model.update')(this.bufferedEvent);
        this.send('closeModal');
      } else {
        this.flash(I18n.t('add_event.error'), 'error');
      }
    },
    
    updateEvent(event, valid) {
      this.set('bufferedEvent', event);
      this.set('valid', valid);
    }
  }
});
