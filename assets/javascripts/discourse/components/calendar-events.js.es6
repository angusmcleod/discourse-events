import DiscourseURL from 'discourse/lib/url';

export default Ember.Component.extend({
  tagName: 'ul',
  classNames: 'calendar-events',

  actions: {
    goToTopic(topicId) {
      DiscourseURL.routeTo('/t/' + topicId);
    }
  }
});
