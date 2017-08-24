import { createWidget } from 'discourse/widgets/widget';
import { ajax } from 'discourse/lib/ajax';
import { h } from 'virtual-dom';

export default createWidget('event-list', {
  tagName: 'div.p-list.event-list',
  buildKey: (attrs) => 'event-list',

  defaultState() {
    return {
      events: [],
      loading: true
    }
  },

  getEvents() {
    const category = this.attrs.customCategory;
    const eventsCategoryId = this.attrs.eventsCategoryId;

    if (!category && !eventsCategoryId) {
      this.state.loading = false;
      this.scheduleRerender();
      return;
    }

    let categoryId = eventsCategoryId || category.id;

    ajax(`/events/${categoryId}`, {type: 'GET', data: {
      period: 'upcoming'
    }}).then((events) => {
      this.state.events = events;
      this.state.loading = false;
      this.scheduleRerender();
    });
  },

  html(attrs, state) {
    const category = this.attrs.customCategory;
    const user = this.currentUser;
    const events = state.events;
    const loading = state.loading;
    let contents = [];

    if (loading) {
      this.getEvents();
      contents.push(h('div.spinner'));
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
})
