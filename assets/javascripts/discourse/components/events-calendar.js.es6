import { default as computed, on } from 'ember-addons/ember-computed-decorators';
import { eventsForDate } from '../lib/date-utilities';

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
      return {
        id: i,
        name: m
      };
    });
  },

  @computed('responsive')
  eventsBelow(responsive) {
    return responsive || this.site.mobileView;
  },

  @computed('currentDate', 'currentMonth', 'topics.[]')
  dateEvents(currentDate, currentMonth, topics) {
    const m = moment().month(currentMonth);
    return eventsForDate(m.date(currentDate), topics, { dateEvents: true });
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
