import DropdownSelectBoxComponent from "select-kit/components/dropdown-select-box";
import computed from 'ember-addons/ember-computed-decorators';

export default DropdownSelectBoxComponent.extend({
  classNames: ["events-calendar-subscription"],
  rowComponent: "events-calendar-subscription-row",

  @computed
  content() {
    const baseUrl = window.location.host + window.location.pathname;

    return [
      {
        id: `webcal://${baseUrl}.ics`,
        name: I18n.t('events_calendar.ical')
      },
      {
        id: `${baseUrl}.rss`,
        name: I18n.t('events_calendar.rss')
      }
    ];
  },

  actions: {
    onSelect() {}
  }
});
