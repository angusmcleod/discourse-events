import { createWidget } from 'discourse/widgets/widget';
import DiscourseURL from 'discourse/lib/url';
import { h } from 'virtual-dom';

export default createWidget('event-list-item', {
  tagName: 'li.event-list-item',

  html(attrs) {
    const event = attrs.item;
    if (!event) { return; };

    let dateTime = moment(event.start).format('MM/DD');
    return [
      h('div.title', event.title),
      h('div.date', dateTime)
    ];
  },

  click() {
    DiscourseURL.routeTo(this.attrs.item.url);
  }
});
