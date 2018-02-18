import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { eventsForDay } from '../lib/date-utilities';

const MAX_EVENTS = 3;

export default Ember.Component.extend({
  classNameBindings: [':day', 'classes'],
  expanded: false,
  hidden: 0,
  hasHidden: Ember.computed.gt('hidden', 0),
  firstDay: Ember.computed.equal('index', 0),

  @on('init')
  @observes('expanded')
  setEvents() {
    const expanded = this.get('expanded');
    const allEvents = this.get('allEvents');
    let events = Object.assign([], allEvents);

    if (events.length && !expanded) {
      let hidden = events.splice(MAX_EVENTS);

      if (hidden.length) {
        this.set('hidden', hidden.length);
      }
    } else {
      this.set('hidden', 0);
    }

    this.set("events", events);
  },

  @computed('day', 'topics.[]', 'expanded')
  allEvents(day, topics, expanded) {
    const firstDay = this.get('firstDay');
    return eventsForDay(day, topics, { firstDay, expanded });
  },

  didInsertElement() {
    this.set('clickHandler', Ember.run.bind(this, this.documentClick));
    Ember.$(document).on('click', this.get('clickHandler'));
  },

  willDestroyElement() {
    Ember.$(document).off('click', this.get('clickHandler'));
  },

  documentClick(event) {
    let $element = this.$();
    let $target = $(event.target);

    if (!$target.closest($element).length) {
      this.clickOutside();
    }
  },

  clickOutside() {
    this.set('expanded', false);
  },

  click() {
    const canSelectDate = this.get('canSelectDate');
    if (canSelectDate) {
      const date = this.get('date');
      const month = this.get('month');
      this.sendAction('selectDate', date, month);
    }
  },

  @computed('index')
  date() {
    const day = this.get('day');
    return day.date();
  },

  @computed('index')
  month() {
    const day = this.get('day');
    return day.month();
  },

  @computed('day', 'currentDate', 'expanded', 'responsive')
  classes(day, currentDate, expanded, responsive) {
    let classes = '';
    if (day.isSame(moment(), "day")) {
      classes += 'today ';
    }
    if (responsive && day.isSame(moment().date(currentDate), "day")) {
      classes += 'selected ';
    }
    if (expanded) {
      classes += 'expanded';
    }
    return classes;
  },

  @computed('expanded')
  containerStyle(expanded) {
    let style = '';

    if (expanded) {
      const offsetLeft = this.$().offset().left;
      const offsetTop = this.$().offset().top;
      const windowWidth = $(window).width();
      const windowHeight = $(window).height();

      if (offsetLeft > (windowWidth / 2)) {
        style += 'right:0;';
      } else {
        style += 'left:0;';
      }

      if (offsetTop > (windowHeight / 2)) {
        style += 'bottom:0;';
      } else {
        style += 'top:0;';
      }
    }

    return Ember.String.htmlSafe(style);
  },

  actions: {
    toggleExpanded() {
      this.toggleProperty('expanded');
    }
  }
});
