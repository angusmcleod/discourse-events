import { default as computed, observes } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  title: 'add_event.modal_title',

  setup() {
    const event = this.get('model.event');

    let start = event && event.start ? event.start : moment();
    let end = event && event.end ? event.end : moment().add(1, 'hours');

    this.setProperties({
      startDate: moment(start).format('YYYY-MM-DD'),
      startTime: moment(start).format('HH:MM'),
      endDate: moment(end).format('YYYY-MM-DD'),
      endTime: moment(end).format('HH:MM')
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
    return !eventStart || !eventEnd || eventStart > eventEnd;
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
    setup() {
      this.setup();
    },

    addEvent() {
      const event = {
        start: this.get('eventStart'),
        end: this.get('eventEnd')
      }

      this.get('model.update')(event);
      this.resetProperties();
      this.send("closeModal");
    }
  }
});
