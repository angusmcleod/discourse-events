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
  observeFields() {
      this.set('eventTimezones', this.get('field.event_timezones')); 
      const inputFields = this.get('inputFields');

      inputFields.forEach(f => {
        Ember.addObserver(this, f, this, () => {
          const field = this.get('field');

          if(!this.get('notReady')) {
            field.setValid(true);
            this.addEventData();
          } else {
            field.setValid(false);
          }
        });
      });
  },

  addEventData() {
    this.set('field.value', addEvent(this.get('event')));
  },

  @discourseComputed('event.startDate', 'event.startTime', 'event.endDate', 'event.endTime', 'event.endEnabled', 'event.allDay')
    notReady(startDate, startTime, endDate, endTime, endEnabled) {
      if (!endEnabled) return false;
      if (moment(endDate).isAfter(moment(startDate), 'day')) return false;
      if (moment(endDate).isBefore(moment(startDate), 'day')) return true;
      return moment(startTime, 'HH:mm').isAfter(moment(endTime, 'HH:mm'));
    },

  @discourseComputed()
  inputFields(){
    return  ['event.startDate', 'event.startTime', 'event.endDate', 'event.endTime', 'event.endEnabled', 'event.allDay', 'event.rsvpEnabled','event.usersGoing', 'event.goingMax' ];
  }
});