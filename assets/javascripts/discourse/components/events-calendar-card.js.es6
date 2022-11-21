import DiscourseURL from 'discourse/lib/url';
import { cookAsync } from 'discourse/lib/text';
import { on } from 'discourse-common/utils/decorators';
import { bind, next, scheduleOnce } from "@ember/runloop";
import Component from "@ember/component";

export default Component.extend({
  classNames: 'events-calendar-card',
  attributeBindings: ["topic.id:data-topic-id"],

  @on('init')
  setup() {
    const excerpt = this.get('topic.excerpt');
    const title = this.get('topic.title');
    cookAsync(excerpt).then((cooked) => this.set('cookedExcerpt', cooked));
    cookAsync(title).then((cooked) => this.set('cookedTitle', cooked));
  },

  didInsertElement() {
    this.set('clickHandler', bind(this, this.documentClick));

    next(() => ($(document).on('mousedown', this.get('clickHandler'))));

    scheduleOnce('afterRender', () => {
      const offsetLeft = this.element.closest('.day').offsetLeft;
      const offsetTop = this.element.closest('.day').offsetTop;
      const windowWidth = $(window).width();
      const windowHeight = $(window).height();

      let styles;

      if (offsetLeft > (windowWidth / 2)) {
        styles = {
          left: "-390px",
          right: "initial"
        }
      } else {
        styles = {
          right: "-390px",
          left: "initial"
        }
      }

      if (offsetTop > (windowHeight / 2)) {
        styles = Object.assign(styles, {
          bottom: "-15px",
          top: "initial"
        });
      } else {
        styles = Object.assign(styles, {
          top: "-15px",
          bottom: "initial"
        });
      }

      Object.keys(styles).forEach(key => {
        this.element.style[key] = styles[key];
      });
    });
  },

  willDestroyElement() {
    $(document).off('mousedown', this.get('clickHandler'));
  },

  documentClick(event) {
    if (!event.target.closest(`div.events-calendar-card[data-topic-id='${this.topic.id}']`)) {
      this.clickOutside();
    }
  },

  clickOutside() {
    this.close();
  },

  close() {
    this.selectEvent();
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
