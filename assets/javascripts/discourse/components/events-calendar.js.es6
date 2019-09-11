import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { eventsForDay, calendarDays, calendarRange } from '../lib/date-utilities';
import Category from 'discourse/models/category';
import { ajax } from 'discourse/lib/ajax';

const RESPONSIVE_BREAKPOINT = 800;
const YEARS = [
  moment().subtract(1, 'year').year(),
  moment().year(),
  moment().add(1, 'year').year()
];
const KEY_ENDPOINT = "/calendar-events/api_keys.json";

export default Ember.Component.extend({
  classNameBindings: [':events-calendar', 'responsive'],
  showEvents: Ember.computed.not('eventsBelow'),
  canSelectDate: Ember.computed.alias('eventsBelow'),
  routing: Ember.inject.service('-routing'),
  queryParams: Ember.computed.alias('routing.router.currentState.routerJsState.fullQueryParams'),
  years: YEARS,

  @on('init')
  setup() {
    this._super();
    moment.locale(I18n.locale);

    Ember.run.scheduleOnce('afterRender', () => {
      this.handleResize();
      $(window).on('resize', Ember.run.bind(this, this.handleResize));
      $('body').addClass('calendar');
    });

    let currentDate = moment().date();
    let currentMonth = moment().month();
    let currentYear = moment().year();

    // get month and year from the date in middle of the event range
    const initialDateRange = this.get('initialDateRange');
    const queryParams = this.get('queryParams');
    let dateRange = {};
    if (initialDateRange) dateRange = initialDateRange;
    if (queryParams.start) dateRange.start = queryParams.start;
    if (queryParams.end) dateRange.end = queryParams.end;

    if (dateRange.start && dateRange.end) {
      const start = moment(dateRange.start);
      const end = moment(dateRange.end);
      const diff = Math.abs(start.diff(end, "days"));
      const middleDay = start.add(diff/2, 'days');
      currentMonth = middleDay.month();
      currentYear = middleDay.year();
    }

    let month = currentMonth;
    let year = currentYear;

    this.setProperties({ currentDate, currentMonth, currentYear, month, year });

    const loginRequired = this.get('siteSettings.login_required');
    const privateCategory = this.get('category.read_restricted');
    const alwaysAddKeys = this.get('siteSettings.events_webcal_always_add_user_api_key');
    if (loginRequired || privateCategory || alwaysAddKeys) {
      ajax(KEY_ENDPOINT, {
        type: 'GET',
      }).then((result) => this.set('userApiKeys', result.api_keys));
    }
  },

  @on('willDestroy')
  teardown() {
    $(window).off('resize', Ember.run.bind(this, this.handleResize));
    $('body').removeClass('calendar');
  },

  handleResize() {
    if (this._state === 'destroying') return;
    const windowWidth = $(window).width();
    const breakpoint = RESPONSIVE_BREAKPOINT;
    this.set("responsive", windowWidth < breakpoint);
  },

  @computed
  months() {
    return moment.localeData().months().map((m, i) => {
      return { id: i, name: m };
    });
  },

  @computed
  showFullTitle() {
    return !this.site.mobileView;
  },

  @computed('responsive')
  eventsBelow(responsive) {
    return responsive || this.site.mobileView;
  },

  @computed('currentDate', 'currentMonth', 'currentYear', 'topics.[]')
  dateEvents(currentDate, currentMonth, currentYear, topics) {
    const day = moment().year(currentYear).month(currentMonth);
    return eventsForDay(day.date(currentDate), topics, { dateEvents: true });
  },

  @computed('currentMonth', 'currentYear')
  days(currentMonth, currentYear) {
    const { start, end } = calendarDays(currentMonth, currentYear);
    let days = [];
    for (var day = moment(start); day.isBefore(end); day.add(1, 'days')) {
      days.push(moment().year(day.year()).month(day.month()).date(day.date()));
    }
    return days;
  },

  @computed('category')
  showSubscription(category) {
    return true // !category || !category.read_restricted;
  },

  transitionToMonth(month, year) {
    const { start, end } = calendarRange(month, year);
    const router = this.get('routing.router');

    if (this.get('loading')) return;
    this.set('loading', true);

    return router.transitionTo({
      queryParams: { start, end }
    }).then(() => {
      const category = this.get('category');
      let filter = '';

      if (category) {
        filter += `c/${Category.slugFor(category)}/l/`;
      }
      filter += 'calendar';

      this.store.findFiltered('topicList', {
        filter,
        params: { start, end }
      }).then(list => {
        this.setProperties({
          topics: list.topics,
          currentMonth: month,
          currentYear: year,
          loading: false
        });
      });
    });
  },

  @observes('month', 'year')
  getNewTopics() {
    const currentMonth = this.get('currentMonth');
    const currentYear = this.get('currentYear');
    const month = this.get('month');
    const year = this.get('year');
    if (currentMonth !== month || currentYear !== year) {
      this.transitionToMonth(month, year);
    }
  },

  actions: {
    selectDate(selectedDate, selectedMonth) {
      const month = this.get('month');
      if (month !== selectedMonth) {
        this.set('month', selectedMonth);
      }
      this.set('currentDate', selectedDate);
    },

    today() {
      this.setProperties({
        month: moment().month(),
        year: moment().year(),
        currentDate: moment().date()
      });
    },

    monthPrevious() {
      let currentMonth = this.get('currentMonth');
      let year = this.get('currentYear');
      let month;

      if (currentMonth === 0) {
        month = 11;
        year = year - 1;
      } else {
        month = currentMonth - 1;
      }

      this.setProperties({ month, year });
    },

    monthNext() {
      let currentMonth = this.get('currentMonth');
      let year = this.get('currentYear');
      let month;

      if (currentMonth === 11) {
        month = 0;
        year = year + 1;
      } else {
        month = currentMonth + 1;
      }

      this.setProperties({ month, year });
    }
  }
});
