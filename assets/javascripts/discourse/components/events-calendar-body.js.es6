import { default as computed, on } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'events-calendar-body',
  expanded: null,

  @on('init')
  setup() {
    this._super();
    moment.locale(I18n.locale);
  },

  @computed('responsive')
  weekdays(responsive) {
    let data = moment.localeData();
    let weekdays = responsive ? Object.assign([],data.weekdaysMin()) : Object.assign([],data.weekdays());
    let firstDay = moment().weekday(0).day();
    let beforeFirst = weekdays.splice(0, firstDay);
    weekdays.push(...beforeFirst);
    return weekdays;
  },

  actions: {
    selectDate(date, month) {
      this.sendAction('selectDate', date, month);
    },

    expand(date) {
      this.set('expanded', date);
    }
  }
});
