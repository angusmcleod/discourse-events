import { default as computed, on } from 'ember-addons/ember-computed-decorators';
import { eventsForDay } from '../lib/date-utilities';

const RESPONSIVE_BREAKPOINT = 800;

export default Ember.Component.extend({
  classNameBindings: [':events-calendar', 'responsive'],
  showEvents: Ember.computed.not('eventsBelow'),
  canSelectDate: Ember.computed.alias('eventsBelow'),

  @on('init')
  setup() {
    this._super();
    moment.locale(I18n.locale);

    Ember.run.scheduleOnce('afterRender', () => {
      this.handleResize();
      $(window).on('resize', Ember.run.bind(this, this.handleResize));
    });

    this.setProperties({
      currentDate: moment().date(),
      currentMonth: moment().month()
    });
  },

  @on('willDestroy')
  teardown() {
    $(window).off('resize', Ember.run.bind(this, this.handleResize));
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

  @computed('responsive')
  eventsBelow(responsive) {
    return responsive || this.site.mobileView;
  },

  @computed('currentDate', 'currentMonth', 'topics.[]')
  dateEvents(currentDate, currentMonth, topics) {
    const day = moment().month(currentMonth);
    return eventsForDay(day.date(currentDate), topics, { dateEvents: true });
  },

  @computed('currentMonth')
  days(currentMonth) {
    const { start, end } = calendarDays(currentMonth);
    let days = [];
    for (var day = moment(start); day.isBefore(end); day.add(1, 'days')) {
      days.push(moment().month(day.month()).date(day.date()));
    }
    return days;
  },

  transitionToMonth(month) {
    const { start, end } = calendarRange(month);
    const router = this.get('routing.router');
    const routeName = router.currentRouteName;

    if (this.get('loading')) return;
    this.set('loading', true);

    return router.transitionTo(routeName, {
      queryParams: { start, end }
    }).then(() => {
      const category = this.get('category');
      let filter = '';

      if (category) {
        filter += `c/${category.get('slug')}/l/`;
      }
      filter += 'calendar';

      this.store.findFiltered('topicList', {
        filter,
        params: { start, end }
      }).then(list => {
        this.setProperties({
          topics: list.topics,
          currentMonth: month,
          loading: false
        });
      });
    });
  },

  @observes('month')
  getNewTopics() {
    const currentMonth = this.get('currentMonth');
    const month = this.get('month');
    if (currentMonth !== month) {
      this.transitionToMonth(month);
    }
  },

  actions: {
    selectDate(date, month) {
      this.setProperties({
        currentDate: date,
        currentMonth: month
      });
    }
  }
});
