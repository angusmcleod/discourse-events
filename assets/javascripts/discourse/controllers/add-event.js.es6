import { default as computed, observes } from 'ember-addons/ember-computed-decorators';
import { setupEvent, timezoneLabel, getTimezone } from '../lib/date-utilities';

const DATE_FORMAT = 'YYYY-MM-DD';
const TIME_FORMAT = 'HH:mm';

export default Ember.Controller.extend({
  title: 'add_event.modal_title',
  endEnabled: false,
  allDay: false,
  showTimezone: false,

  setup() {
    const event = this.get('model.event');
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

    this.setProperties(props);
    this.setupTimePicker('start');
    this.setupTimePicker('end');
  },

  setupTimePicker(type) {
    const time = this.get(`${type}Time`);
    Ember.run.scheduleOnce('afterRender', this, () => {
      const $timePicker = $(`#${type}-time-picker`);
      $timePicker.timepicker({ timeFormat: 'H:i' });
      $timePicker.timepicker('setTime', time);
      $timePicker.change(() => this.set(`${type}Time`, $timePicker.val()));
    });
  },

  @observes('endEnabled')
  setupOnEndEnabled() {
    const endEnabled = this.get('endEnabled');
    if (endEnabled) {
      const endDate = this.get('endDate');
      if (!endDate) {
        this.set('endDate', this.get('startDate'));
      }

      const allDay = this.get('allDay');
      if (!allDay) {
        const endTime = this.get('endTime');
        if (!endTime) {
          this.set('endTime', this.get('startTime'));
        }

        this.setupTimePicker('end');
      }
    }
  },

  @observes('allDay')
  setupOnAllDayRevert() {
    const allDay = this.get('allDay');
    if (!allDay) {
      const start = this.nextInterval();
      const startTime = start.format(TIME_FORMAT);
      this.set('startTime', startTime);
      this.setupTimePicker('start');

      const endEnabled = this.get('endEnabled');
      if (endEnabled) {
        const end = moment(start).add(1, 'hours');
        const endTime = end.format(TIME_FORMAT);
        this.set('endTime', endTime);
        this.setupTimePicker('end');
      }
    }
  },

  nextInterval() {
    const ROUNDING = 30 * 60 * 1000;
    return moment(Math.ceil((+moment()) / ROUNDING) * ROUNDING);
  },

  @computed
  timezones() {
    return this.site.event_timezones.map((tz) => {
      return {
        value: tz.value,
        name: timezoneLabel(tz.value)
      }
    });
  },

  @computed('startDate', 'startTime', 'endDate', 'endTime', 'endEnabled', 'allDay')
  notReady(startDate, startTime, endDate, endTime, endEnabled) {
    if (!endEnabled) return false;
    if (moment(endDate).isAfter(moment(startDate), 'day')) return false;
    if (moment(endDate).isBefore(moment(startDate), 'day')) return true;
    return moment(startTime, 'HH:mm').isAfter(moment(endTime, 'HH:mm'));
  },

  resetProperties() {
    this.setProperties({
      startDate: null,
      startTime: null,
      endDate: null,
      endTime: null,
      endEnabled: false,
      allDay: false,
      rsvpEnabled: false,
      goingMax: null
    });
  },

  actions: {
    clear() {
      this.resetProperties();
      this.get('model.update')(null);
    },

    clearTimezone() {
      this.set("timezone", null);
      this.toggleProperty('showTimezone');
    },

    addEvent() {
      const startDate = this.get('startDate');
      let event = null;

      if (startDate) {
        let start = moment();

        const timezone = this.get('timezone');
        start.tz(timezone);

        const allDay = this.get('allDay');
        const sYear = moment(startDate).year();
        const sMonth = moment(startDate).month();
        const sDate = moment(startDate).date();
        const startTime = this.get('startTime');
        let sHour = allDay ? 0 : moment(startTime, 'HH:mm').hour();
        let sMin = allDay ? 0 : moment(startTime, 'HH:mm').minute();

        event = {
          timezone,
          all_day: allDay,
          start: start.year(sYear).month(sMonth).date(sDate).hour(sHour).minute(sMin).toISOString()
        };

        const endEnabled = this.get('endEnabled');
        if (endEnabled) {
          let end = moment();
          if (timezone) end.tz(timezone);

          const endDate = this.get('endDate');
          const eYear = moment(endDate).year();
          const eMonth = moment(endDate).month();
          const eDate = moment(endDate).date();
          const endTime = this.get('endTime');
          let eHour = allDay ? 0 : moment(endTime, 'HH:mm').hour();
          let eMin = allDay ? 0 : moment(endTime, 'HH:mm').minute();

          event['end'] = end.year(eYear).month(eMonth).date(eDate).hour(eHour).minute(eMin).toISOString();
        }
      }

      if (this.get('rsvpEnabled')) {
        event['rsvp'] = true;

        let goingMax = this.get('goingMax');
        if (goingMax) {
          event['going_max'] = goingMax;
        }

        let usersGoing = this.get('usersGoing');
        if (usersGoing) {
          event['going'] = usersGoing.split(',')
        }
      }

      this.get('model.update')(event);
      this.resetProperties();
      this.send("closeModal");
    }
  }
});
