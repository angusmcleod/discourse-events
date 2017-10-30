import { createWidget } from 'discourse/widgets/widget';
import { ajax } from 'discourse/lib/ajax';
import { h } from 'virtual-dom';

export default createWidget('event-list', {
  tagName: 'div.widget-list',
  buildKey: () => 'event-list',

  defaultState() {
    return {
      events: [],
      loading: true
    };
  },

  getEvents() {
    const category = this.attrs.category;

    if (!category) {
      this.state.loading = false;
      this.scheduleRerender();
      return;
    }

    ajax(`/events/l/${category.id}`, {type: 'GET', data: {
      period: 'upcoming'
    }}).then((events) => {
      this.state.events = events;
      this.state.loading = false;
      this.scheduleRerender();
    });
  },

  html(attrs, state) {
    const category = this.attrs.category;
    const events = state.events;
    const loading = state.loading;
    let contents = [];

    if (loading) {
      this.getEvents();
      contents.push(h('div.spinner.small'));
    } else {
      let listContents = [h('div.no-events', I18n.t('event_list.no_results'))];

      if (events.length > 0) {
        listContents = events.map((event) => this.attach('event', {event}));
      }

      contents.push(h('ul', listContents));
    }

    if (attrs.includeControls) {
      contents.push(this.attach('event-list-controls', {category}));
    }

    return contents;
  }
});
