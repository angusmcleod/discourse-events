import { default as computed, observes } from 'ember-addons/ember-computed-decorators';

const DATE_FORMAT = 'YYYY-MM-DD';
const TIME_FORMAT = 'HH:mm';

export default Ember.Controller.extend({
  title: 'add_event.modal_title',
  endEnabled: false,
  allDay: false,

  setup() {
    const event = this.get('model.event');

    if (event && event.start && event.end) {
      let start = moment(event.start);
      let end = moment(event.end);
      const startIsDayStart = start.hour() === 0 && start.minute() === 0;
      const endIsDayEnd = end.hour() === 23 && end.minute() === 59;

      if (startIsDayStart && endIsDayEnd) {
        let startDate = start.format(DATE_FORMAT);
        let endDate = end.format(DATE_FORMAT);
        let endEnabled = moment(endDate).isAfter(startDate, 'day');

        return this.setProperties({
          allDay: true,
          startDate,
          endDate,
          endEnabled
        });
      }
    }

    let start = event && event.start ? moment(event.start) : this.nextInterval();
    let startDate = start.format(DATE_FORMAT);
    let startTime = start.format(TIME_FORMAT);
    this.setProperties({ startDate, startTime });
    this.setupTimePicker('start');

    if (event && event.end) {
      this.set('endEnabled', true);
    }
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
      const event = this.get('model.event');
      const eventStart = this.get('eventStart');
      const end = event && event.end ? moment(event.end) : moment(eventStart).add(1, 'hours');

      const endDate = end.format(DATE_FORMAT);
      this.set('endDate', endDate);

      const allDay = this.get('allDay');
      if (!allDay) {
        const endTime = end.format(TIME_FORMAT);
        this.setProperties({ endDate, endTime });
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

  dateTime(date, time) {
    return moment(date + 'T' + time).format();
  },

  @computed('startDate', 'startTime', 'allDay')
  eventStart(date, time, allDay) {
    if (allDay) time = moment(date).startOf('day').format(TIME_FORMAT);
    return date && time ? this.dateTime(date, time) : '';
  },

  @computed('endDate', 'endTime', 'allDay', 'endEnabled')
  eventEnd(date, time, allDay, endEnabled) {
    if (allDay) {
      date = endEnabled ? date : this.get('startDate');
      time = moment(date).endOf('day').format(TIME_FORMAT);
    }
    return date && time ? this.dateTime(date, time) : '';
  },

  @computed('eventStart', 'eventEnd', 'endEnabled', 'allDay')
  notReady(eventStart, eventEnd, endEnabled, allDay) {
    if (allDay) return moment(eventStart).isAfter(eventEnd, 'day');
    return moment().isAfter(eventStart) || (endEnabled && eventStart > eventEnd);
  },

  resetProperties() {
    this.setProperties({
      startDate: null,
      startTime: null,
      endDate: null,
      endTime: null,
      endEnabled: false,
      allDay: false
    });
  },

  actions: {
    clear() {
      this.resetProperties();
      this.get('model.update')(null);
    },

    addEvent() {
      const start = this.get('eventStart');
      let event = null;

      if (start && start.length > 0) {
        event = { start };

        const endEnabled = this.get('endEnabled');
        const allDay = this.get('allDay');
        if (endEnabled || allDay) {
          event['end'] = this.get('eventEnd');
        };
      }

      this.get('model.update')(event);
      this.resetProperties();
      this.send("closeModal");
    }
  }
});
