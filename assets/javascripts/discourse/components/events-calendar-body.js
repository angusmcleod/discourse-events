import Component from "@ember/component";
import {
  default as discourseComputed,
  observes,
  on,
} from "discourse-common/utils/decorators";
import I18n from "I18n";
import { firstDayOfWeek } from "../lib/date-utilities";

export default Component.extend({
  classNames: "events-calendar-body",
  expandedDate: 0.0,

  @on("init")
  setup() {
    this._super();
    moment.locale(I18n.locale);
  },

  @discourseComputed("responsive")
  weekdays(responsive) {
    let data = moment.localeData();
    let weekdays = $.extend(
      [],
      responsive ? data.weekdaysMin() : data.weekdays()
    );
    let firstDay = firstDayOfWeek();
    let beforeFirst = weekdays.splice(0, firstDay);
    weekdays.push(...beforeFirst);
    return weekdays;
  },

  @observes("currentMonth")
  resetExpandedDate() {
    this.set("expandedDate", null);
  },

  actions: {
    setExpandedDate(date) {
      event?.preventDefault();
      const month = this.get("currentMonth");
      this.set("expandedDate", month + "." + date);
    },
  },
});
