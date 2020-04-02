import Component from "@ember/component";
import { alias } from "@ember/object/computed";
import { addEvent, setupEvent } from '../../discourse/lib/date-utilities';

export default Component.extend({
  layoutName: "javascripts/wizard/templates/components/wizard-field-event",
  eventTimezones: alias('field.event_timezones'),
  event: {},

  actions: {
    updateEvent(event, status){
      this.set('field.value', event);
      this.field.setValid(status);
    }
  }
});
