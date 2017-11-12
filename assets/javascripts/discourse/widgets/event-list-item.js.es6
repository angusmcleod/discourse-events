import { createWidget } from 'discourse/widgets/widget';
import { h } from 'virtual-dom';

export default createWidget('event', {
  tagName: 'li.event-link',

  html(attrs) {
    const event = attrs.item;
    if (!event) { return; };

    let dateTime = moment(event.start).format('MM/DD');
    return [
      h('a', { href: event.url }, h('div.title', event.title)),
      h('div.date', dateTime)
    ];
  }
});
