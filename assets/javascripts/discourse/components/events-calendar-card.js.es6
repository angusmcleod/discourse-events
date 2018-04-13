import DiscourseURL from 'discourse/lib/url';

export default Ember.Component.extend({
  classNames: 'events-calendar-card',

  didInsertElement() {
    this.set('clickHandler', Ember.run.bind(this, this.documentClick));
    Ember.run.next(() => {
      Ember.$(document).on('click', this.get('clickHandler'));
    });

    Ember.run.scheduleOnce('afterRender', () => {
      const offsetLeft = this.$().closest('.day').offset().left;
      const windowWidth = $(window).width();

      let css;
      if (offsetLeft > (windowWidth / 2)) {
        css = {
          left: "-390px",
          right: "initial"
        }
      } else {
        css = {
          right: "-390px",
          left: "initial"
        }
      }

      this.$().css(css);
    });
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
    this.close();
  },

  close() {
    this.sendAction('selectEvent');
  },

  actions: {
    goToTopic() {
      const url = this.get('topic.url');
      DiscourseURL.routeTo(url);
    },

    close() {
      this.close();
    }
  }
})
