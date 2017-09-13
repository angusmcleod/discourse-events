import { default as computed, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  title: 'add_event.modal_title',

  setup() {
    const event = this.get('model.event');

    const ROUNDING = 30 * 60 * 1000;
    const nextInterval = moment(Math.ceil((+moment()) / ROUNDING) * ROUNDING);
    let start = event && event.start ? moment(event.start) : nextInterval;
    let end = event && event.end ? moment(event.end) : nextInterval.clone().add(1, 'hours');
    const startDate = start.format('YYYY-MM-DD');
    const startTime = start.format('HH:mm');
    const endDate = end.format('YYYY-MM-DD');
    const endTime = end.format('HH:mm');

    this.setProperties({ startDate, startTime, endDate, endTime });

    Ember.run.scheduleOnce('afterRender', this, () => {
      const $startTimePicker = $("#start-time-picker");
      const $endTimePicker = $("#end-time-picker");

      $startTimePicker.timepicker({ timeFormat: 'H:i' });
      $endTimePicker.timepicker({ timeFormat: 'H:i' });

      $startTimePicker.timepicker('setTime', startTime);
      $endTimePicker.timepicker('setTime', endTime);

      $startTimePicker.change(() => this.set('startTime', $startTimePicker.val()));
      $endTimePicker.change(() => this.set('endTime', $endTimePicker.val()));
    })
  },

  dateTime: function(date, time) {
    return moment(date + 'T' + time).format();
  },

  @computed('startDate', 'startTime')
  eventStart(date, time) {
    return date && time ? this.dateTime(date, time) : '';
  },

  @computed('endDate', 'endTime')
  eventEnd(date, time) {
    return date && time ? this.dateTime(date, time) : '';
  },

  @computed('eventStart','eventEnd')
  notReady(eventStart, eventEnd) {
    return eventStart > eventEnd;
  },

  resetProperties() {
    this.setProperties({
      startDate: null,
      startTime: null,
      endDate: null,
      endTime: null
    })
  },

  actions: {
    clear() {
      this.resetProperties();
      this.get('model.update')(null);
    },

    addEvent() {
      let event = {
        start: this.get('eventStart'),
        end: this.get('eventEnd')
      }

      if (event['start'] == '' || event['end'] == '') {
        event = null;
      }

      this.get('model.update')(event);
      this.resetProperties();
      this.send("closeModal");
    }
  }
});
