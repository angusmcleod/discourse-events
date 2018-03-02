import { googleUri, icsUri } from '../lib/date-utilities';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  expanded: false,
  classNames: 'add-to-calendar',

  didInsertElement() {
    Ember.$(document).on('click', Ember.run.bind(this, this.outsideClick));
  },

  willDestroyElement() {
    Ember.$(document).off('click', Ember.run.bind(this, this.outsideClick));
  },

  outsideClick(e) {
    if (!this.isDestroying && !$(e.target).closest('.add-to-calendar').length) {
      this.set('expanded', false);
    }
  },

  @computed('topic.event')
  calendarUris() {
    const topic = this.get('topic');

    let params = {
      event: topic.event,
      title: topic.title,
      url: window.location.hostname + topic.get('url')
    };

    if (topic.location && topic.location.geo_location) {
      params['location'] = topic.location.geo_location.address;
    }

    return [
      { uri: googleUri(params), label: 'google' },
      { uri: icsUri(params), label: 'ics' },
    ];
  },

  actions: {
    expand() {
      this.toggleProperty('expanded');
    }
  }
});
