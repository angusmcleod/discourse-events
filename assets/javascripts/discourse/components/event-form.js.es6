import Component from "@ember/component";
import {
  observes,
  default as discourseComputed
} from "discourse-common/utils/decorators";
import { scheduleOnce, later } from "@ember/runloop";
import { setupEvent, timezoneLabel, getTimezone } from '../lib/date-utilities';

const DATE_FORMAT = 'YYYY-MM-DD';
const TIME_FORMAT = 'HH:mm';
export default Component.extend({
  title: 'add_event.modal_title',
  endEnabled: false,
  allDay: false,
  showTimezone: false,
  event: {},
  
  @discourseComputed('event.startDate', 'event.startTime', 'event.endDate', 'event.endTime', 'event.endEnabled', 'event.allDay')
  notReady(startDate, startTime, endDate, endTime, endEnabled) {
    if (!endEnabled) return false;
    if (moment(endDate).isAfter(moment(startDate), 'day')) return false;
    if (moment(endDate).isBefore(moment(startDate), 'day')) return true;
    return moment(startTime, 'HH:mm').isAfter(moment(endTime, 'HH:mm'));
  },

  @observes('event.startDate', 'event.startTime', 'event.endDate', 'event.endTime', 'event.endEnabled', 'event.allDay')
  validate(){
    this.validateEvent(!this.get('notReady'));
  },

  didInsertElement() {
    const event = this.get('event');
    const { start, end, allDay, multiDay, timezone } = setupEvent(event, { useEventTimezone: true });
    let props = {};

    if (allDay) {
      let startDate = start.format(DATE_FORMAT);
      let endDate = end ? end.format(DATE_FORMAT) : startDate;
      let endEnabled = moment(endDate).isAfter(startDate, 'day');

      props = {
        allDay,
        startDate,
        endDate,
        endEnabled,
      };
    } else if (start) {
      props['startDate'] = start.format(DATE_FORMAT);
      props['startTime'] = start.format(TIME_FORMAT);

      if (end) {
        let endDate = end.format(DATE_FORMAT);
        let endTime = end.format(TIME_FORMAT);
        props['endDate'] = endDate;
        props['endTime'] = endTime;
        props['endEnabled'] = true;
      }
    } else {
      props['startDate'] = moment().format(DATE_FORMAT);
      props['startTime'] = this.nextInterval().format(TIME_FORMAT);
    }

    props['timezone'] = timezone;

    if (event && event.rsvp) {
      props['rsvpEnabled'] = true;

      if (event.going_max) {
        props['goingMax'] = event.going_max;
      }

      if (event.going) {
        props['usersGoing'] = event.going.join(',');
      }
    }

    this.set('event', props);
    this.setupTimePicker('start');
    this.setupTimePicker('end');
  },

  setupTimePicker(type) {
    const time = this.get(`event.${type}Time`);
    later(this, () => {
      scheduleOnce('afterRender', this, () => {
        const $timePicker = $(`#${type}-time-picker`);
        $timePicker.timepicker({ timeFormat: 'H:i' });
        $timePicker.timepicker('setTime', time);
        $timePicker.change(() => this.set(`event.${type}Time`, $timePicker.val()));
      });
    });
  },

  @observes('event.endEnabled')
  setupOnEndEnabled() {
    const endEnabled = this.get('event.endEnabled');
    if (endEnabled) {
      const endDate = this.get('event.endDate');
      if (!endDate) {
        this.set('event.endDate', this.get('event.startDate'));
      }

      const allDay = this.get('event.allDay');
      if (!allDay) {
        const endTime = this.get('event.endTime');
        if (!endTime) {
          this.set('event.endTime', this.get('event.startTime'));
        }

        this.setupTimePicker('end');
      }
    }
  },

  @observes('event.allDay')
  setupOnAllDayRevert() {
    const allDay = this.get('event.allDay');
    if (!allDay) {
      const start = this.nextInterval();
      const startTime = start.format(TIME_FORMAT);
      this.set('event.startTime', startTime);
      this.setupTimePicker('start');

      const endEnabled = this.get('event.endEnabled');
      if (endEnabled) {
        const end = moment(start).add(1, 'hours');
        const endTime = end.format(TIME_FORMAT);
        this.set('event.endTime', endTime);
        this.setupTimePicker('end');
      }
    }
  },

  @discourseComputed()
  timezones() {
    const event_timezones = this.get('eventTimezones') || this.site.event_timezones; 
    return event_timezones.map((tz) => {
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
});
