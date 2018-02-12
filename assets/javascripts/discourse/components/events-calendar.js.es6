import { default as computed, on } from 'ember-addons/ember-computed-decorators';
import { eventsForDate } from '../lib/date-utilities';

const RESPONSIVE_BREAKPOINT = 800;

export default Ember.Component.extend({
  classNameBindings: [':events-calendar', 'responsive'],
  showEvents: Ember.computed.not('eventsBelow'),
  selectDates: Ember.computed.alias('eventsBelow'),

  @on('init')
  setup() {
    this._super();
    moment.locale(I18n.locale);

    Ember.run.scheduleOnce('afterRender', () => {
      this.handleResize();
      $(window).on('resize', Ember.run.bind(this, this.handleResize));
    });

    this.setProperties({
      date: moment().date(),
      month: moment().format('MMMM')
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
    return moment.localeData().months();
  },

  @computed('responsive')
  eventsBelow(responsive) {
    return responsive || this.site.mobileView;
  },

  @computed('date', 'month', 'topics.[]')
  dateEvents(date, month, topics) {
    const m = moment().month(month);
    return eventsForDate(m.date(date), topics, { dateEvents: true });
  },

  actions: {
    setDate(date, monthNum) {
      const months = this.get('months');
      let month = months[monthNum];
      this.setProperties({
        date,
        month
      });
    }
  }
});
