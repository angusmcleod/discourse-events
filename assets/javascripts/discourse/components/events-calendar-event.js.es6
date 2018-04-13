import DiscourseURL from 'discourse/lib/url';

export default Ember.Component.extend({
  tagName: 'li',

  actions: {
    selectEvent(url) {
      const mobile = this.site.mobileView;
      if (mobile) {
        DiscourseURL.routeTo(url);
      } else {
        this.toggleProperty('showEventCard');
      }
    }
  }
})
