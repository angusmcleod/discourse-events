import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';
import { eventsForDay } from '../lib/date-utilities';

const MAX_EVENTS = 4;

export default Ember.Component.extend({
  classNameBindings: [':day', 'classes', 'differentMonth'],
  hidden: 0,
  hasHidden: Ember.computed.gt('hidden', 0),

  @computed('date', 'month', 'expandedDate')
  expanded(date, month, expandedDate) {
    return `${month}.${date}` === expandedDate;
  },

  @computed('month', 'currentMonth')
  differentMonth(month, currentMonth) {
    return month !== currentMonth
  },

  @on('init')
  @observes('expanded')
  setEvents() {
    const expanded = this.get('expanded');
    const allEvents = this.get('allEvents');
    let events = $.extend([], allEvents);

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

  @computed('day', 'topics.[]', 'expanded', 'rowIndex')
  allEvents(day, topics, expanded, rowIndex) {
    return eventsForDay(day, topics, { rowIndex, expanded });
  },

  @computed('index')
  rowIndex(index) {
    return index % 7;
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
    if (this.get('expanded')) {
      this.get('setExpandedDate')(null);
    }
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

  @computed('day', 'currentDate', 'currentMonth', 'expanded', 'responsive')
  classes(day, currentDate, currentMonth, expanded, responsive) {
    let classes = '';
    if (day.isSame(moment(), "day")) {
      classes += 'today ';
    }
    if (responsive && day.isSame(moment().month(currentMonth).date(currentDate), "day")) {
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
  }
});
