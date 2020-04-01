import Component from "@ember/component";
import {
  on,
  observes,
  default as discourseComputed
} from "discourse-common/utils/decorators";
import { addEvent, setupEvent } from '../../discourse/lib/date-utilities';

export default Component.extend({
  layoutName: "javascripts/wizard/templates/components/wizard-field-event",

  @on('init')
  setTimezones() {
      this.set('eventTimezones', this.get('field.event_timezones')); 
  },

  addEventData() {
    this.set('field.value', addEvent(this.get('event')));
  },

  actions: {
    validateEvent(status){
      let field = this.get('field');
      field.setValid(status);
    }
  }
});
