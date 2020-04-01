import Component from "@ember/component";
import {
  on,
  observes,
  default as discourseComputed
} from "discourse-common/utils/decorators";
import { addEvent, setupEvent } from '../../discourse/lib/date-utilities';

export default Component.extend({
  layoutName: "javascripts/wizard/templates/components/wizard-field-event",
  inputFields: ['event.startDate', 'event.startTime', 'event.endDate', 'event.endTime', 'event.endEnabled', 'event.allDay', 'event.rsvpEnabled','event.usersGoing', 'event.goingMax' ],

  @on('init')
  setup() {
    this.set('eventTimezones', this.get('field.event_timezones'));
    this.set('event', {});

    this.inputFields.forEach(f => {
      Ember.addObserver(this, f, this, () => {
        if(this.get('field.valid')) {
          this.addEventData();
        }
      });
    });
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
