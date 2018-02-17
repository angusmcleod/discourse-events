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

  @computed('month')
  days(month) {
    const firstDayMonth = moment().month(month).date(1);
    const firstDayLocale = moment().weekday(0).day();

    let start;
    let diff;
    if (firstDayMonth.day() >= firstDayLocale) {
      diff = firstDayMonth.day() - firstDayLocale;
      start = firstDayMonth.day(firstDayLocale);
    } else {
      if (firstDayLocale === 1) {
        // firstDayMonth has to be 0, i.e. Sunday
        diff = 6;
      } else {
        // islamic calendar starts on 6, i.e. Saturday
        diff = firstDayMonth.day() + 1;
      }
      start = firstDayMonth.subtract(diff, 'days');
    }

    let dayCount = 35;
    if ((diff + moment().month(month).daysInMonth()) > 35) dayCount = 42;

    const end = moment(start).add(dayCount, 'days');

    let days = [];
    for (var day = moment(start); day.isBefore(end); day.add(1, 'days')) {
      days.push(moment().month(day.month()).date(day.date()));
    }

    return days;
  },

  actions: {
    setDate(date, monthNum) {
      const selectDates = this.get('selectDates');
      if (selectDates) {
        this.sendAction('setDate', date, monthNum);
      }
    },

    expand(date) {
      this.set('expanded', date);
    }
  }
});
