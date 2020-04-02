import Component from "@ember/component";
import { observes, default as discourseComputed } from "discourse-common/utils/decorators";
import { scheduleOnce, later } from "@ember/runloop";
import { compileEvent, setupEventForm, timezoneLabel, getTimezone, formTimeFormat } from '../lib/date-utilities';

export default Component.extend({
  title: 'add_event.modal_title',
  endEnabled: false,
  allDay: false,
  showTimezone: false,
  
  didInsertElement() {    
    const props = setupEventForm(this.event);
    this.setProperties(props);
    this.setupTimePicker('start');
    this.setupTimePicker('end');
  },
  
  @discourseComputed()
  endValid() {
    return !this.endEnabled ||
      (!moment(this.endDate).isBefore(moment(this.startDate), 'day') &&
      moment(this.endTime, 'HH:mm').isAfter(moment(this.startTime, 'HH:mm')));
  },

  @observes('startDate', 'startTime', 'endDate', 'endTime', 'endEnabled', 'allDay')
  eventUpdated(){
    const ready = this.endValid;
    const event = compileEvent({
      startDate: this.startDate,
      startTime: this.startTime,
      endDate: this.endDate,
      endTime: this.endTime,
      endEnabled: this.endEnabled,
      allDay: this.allDay,
      timezone: this.timezone,
      rsvpEnabled: this.rsvpEnabled,
      goingMax: this.goingMax,
      usersGoing: this.usersGoing
    });
    
    this.updateEvent(event, ready);
  },

  setupTimePicker(type) {    
    const time = this.get(`${type}Time`);
    later(this, () => {
      scheduleOnce('afterRender', this, () => {
        const $timePicker = $(`#${type}-time-picker`);
        $timePicker.timepicker({ timeFormat: 'H:i' });
        $timePicker.timepicker('setTime', time);
        $timePicker.change(() => {
          this.set(`${type}Time`, $timePicker.val());
        });
      })
    });
  },

  @discourseComputed()
  timezones() {
    const eventTimezones = this.get('eventTimezones') || this.site.event_timezones; 
    return eventTimezones.map((tz) => {
      return {
        value: tz.value,
        name: timezoneLabel(tz.value)
      }
    });
  },

  nextInterval() {
    const ROUNDING = 30 * 60 * 1000;
    return moment(Math.ceil((+moment()) / ROUNDING) * ROUNDING);
  },
  
  actions: {
    toggleEndEnabled(value) {
      this.set('endEnabled', value);
      
      if (value) {
        if (!this.endDate) {
          this.set('endDate', this.startDate);
        }
        
        if (!this.allDay) {
          if (!this.endTime) {
            this.set('endTime', this.startTime);
          }
          
          this.setupTimePicker('end');
        }
      }
    },
    
    toggleAllDay(value) {
      this.set('allDay', value);
      
      if (!value) {
        const start = this.nextInterval();
        
        this.set('startTime', start.format(formTimeFormat));
        this.setupTimePicker('start');

        if (this.endEnabled) {
          const end = moment(start).add(1, 'hours');
                    
          this.set('endTime', end.format(formTimeFormat));
          this.setupTimePicker('end');
        }
      }
    }
  }
});
