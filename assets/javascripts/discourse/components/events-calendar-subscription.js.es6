import DropdownSelectBoxComponent from "select-kit/components/dropdown-select-box";
import computed from 'ember-addons/ember-computed-decorators';

export default DropdownSelectBoxComponent.extend({
  classNames: ["events-calendar-subscription"],
  rowComponent: "events-calendar-subscription-row",

  @computed
  content() {
    const baseUrl = window.location.host + window.location.pathname;
    const timeZone = moment.tz.guess();
    return [
      {
        id: `webcal://${baseUrl}.ics?time_zone=${timeZone}`,
        name: I18n.t('events_calendar.ical')
      },
      {
        id: `${baseUrl}.rss?time_zone=${timeZone}`,
        name: I18n.t('events_calendar.rss')
      }
    ];
  },

  actions: {
    onSelect() {}
  }
});
