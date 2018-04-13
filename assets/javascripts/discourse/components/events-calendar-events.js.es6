import DiscourseURL from 'discourse/lib/url';

export default Ember.Component.extend({
  tagName: 'ul',
  classNames: 'events-calendar-events',

  actions: {
    goToTopic(topicId) {
      DiscourseURL.routeTo('/t/' + topicId);
    }
  }
});
