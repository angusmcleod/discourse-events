import DiscourseURL from 'discourse/lib/url';
import { cookAsync } from 'discourse/lib/text';
import { on } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'events-calendar-card',

  @on('init')
  setup() {
    const excerpt = this.get('topic.excerpt');
    const title = this.get('topic.title');
    cookAsync(excerpt).then((cooked) => this.set('cookedExcerpt', cooked));
    cookAsync(title).then((cooked) => this.set('cookedTitle', cooked));
  },

  didInsertElement() {
    this.set('clickHandler', Ember.run.bind(this, this.documentClick));

    Ember.run.next(() => {
      Ember.$(document).on('mousedown', this.get('clickHandler'));
    });

    Ember.run.scheduleOnce('afterRender', () => {
      const offsetLeft = this.$().closest('.day').offset().left;
      const offsetTop = this.$().closest('.day').offset().top;
      const windowWidth = $(window).width();
      const windowHeight = $(window).height();

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

      if (offsetTop > (windowHeight / 2)) {
        css = $.extend(css, {
          bottom: "-15px",
          top: "initial"
        });
      } else {
        css = $.extend(css, {
          top: "-15px",
          bottom: "initial"
        });
      }

      this.$().css(css);
    });
  },

  willDestroyElement() {
    Ember.$(document).off('mousedown', this.get('clickHandler'));
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
