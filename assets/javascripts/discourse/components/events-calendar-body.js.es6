import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { firstDayOfWeek } from '../lib/date-utilities';

export default Ember.Component.extend({
  classNames: 'events-calendar-body',
  expandedDate: 0.0,

  @on('init')
  setup() {
    this._super();
    moment.locale(I18n.locale);
  },

  @computed('responsive')
  weekdays(responsive) {
    let data = moment.localeData();
    let weekdays = $.extend([], responsive ? data.weekdaysMin() : data.weekdays());
    let firstDay = firstDayOfWeek();
    let beforeFirst = weekdays.splice(0, firstDay);
    weekdays.push(...beforeFirst);
    return weekdays;
  },

  @observes('currentMonth')
  resetExpandedDate() {
    this.set('expandedDate', null);
  },

  actions: {
    selectDate(date, month) {
      this.sendAction('selectDate', date, month);
    },

    setExpandedDate(date) {
      const month = this.get('currentMonth');
      this.set('expandedDate', month + '.' + date);
    }
  }
});
