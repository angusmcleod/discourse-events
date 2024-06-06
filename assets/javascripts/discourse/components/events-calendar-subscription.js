import Category from "discourse/models/category";
import getURL from "discourse-common/lib/get-url";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import DropdownSelectBoxComponent from "select-kit/components/dropdown-select-box";

export default DropdownSelectBoxComponent.extend({
  classNames: ["events-calendar-subscription"],

  modifyComponentForRow() {
    return "events-calendar-subscription-row";
  },

  getDomain() {
    return location.hostname + (location.port ? ":" + location.port : "");
  },

  @discourseComputed()
  content() {
    const path = this.category ? `/c/${Category.slugFor(this.category)}/l` : "";
    const url = this.getDomain() + getURL(path);
    const timeZone = moment.tz.guess();
    return [
      {
        id: `webcal://${url}/calendar.ics?time_zone=${timeZone}`,
        name: I18n.t("events_calendar.ical"),
      },
      {
        id: `${url}/calendar.rss?time_zone=${timeZone}`,
        name: I18n.t("events_calendar.rss"),
      },
    ];
  },

  actions: {
    onSelect() {},
  },
});
