import DiscourseURL from 'discourse/lib/url';

export default Ember.Component.extend({
  tagName: 'li',

  actions: {
    selectEvent(url) {
      const responsive = this.get('responsive');
      if (responsive) {
        DiscourseURL.routeTo(url);
      } else {
        this.toggleProperty('showEventCard');
      }
    }
  }
})
