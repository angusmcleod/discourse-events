import { default as computed, on, observes } from 'ember-addons/ember-computed-decorators';

const MAX_EVENTS = 3;

export default Ember.Component.extend({
  classNameBindings: [':day', 'classes'],
  expanded: false,
  hidden: 0,
  hasHidden: Ember.computed.gt('hidden', 0),

  @on('init')
  @observes('expanded')
  setEvents() {
    const expanded = this.get('expanded');
    const allEvents = this.get('day.events');
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
    const date = this.get('day.date');
    const month = this.get('day.monthNum');
    this.sendAction('setDate', date, month);
  },

  @computed('day.classes', 'expanded')
  classes(classes, expanded) {
    if (expanded) {
      classes += ' expanded';
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
