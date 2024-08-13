import { next } from "@ember/runloop";
import DatePicker from "discourse/components/date-picker";
import loadScript from "discourse/lib/load-script";
import { deepMerge } from "discourse-common/lib/object";
import { observes, on } from "discourse-common/utils/decorators";
import I18n from "I18n";
import { firstDayOfWeek } from "../lib/date-utilities";

export default DatePicker.extend({
  layoutName: "components/date-picker",

  @observes("value")
  setDate() {
    if (this._picker && this.value) {
      this._picker.setDate(this.value);
    }
  },

  @on("didInsertElement")
  _loadDatePicker() {
    const input = this.element.querySelector(".date-picker");
    const container = document.getElementById(this.get("containerId"));

    loadScript("/javascripts/pikaday.js").then(() => {
      next(() => {
        let default_opts = {
          field: input,
          container: container || this.element,
          bound: container === undefined,
          format: "YYYY-MM-DD",
          firstDay: firstDayOfWeek(),
          i18n: {
            previousMonth: I18n.t("dates.previous_month"),
            nextMonth: I18n.t("dates.next_month"),
            months: moment.months(),
            weekdays: moment.weekdays(),
            weekdaysShort: moment.weekdaysShort(),
          },
          onSelect: (date) => {
            const formattedDate = moment(date).format("YYYY-MM-DD");

            if (this.onSelect) {
              this.onSelect(formattedDate);
            }

            if (!this.element || this.isDestroying || this.isDestroyed) {
              return;
            }

            this.set("value", formattedDate);
          },
        };

        this._picker = new Pikaday(deepMerge(default_opts, this._opts())); // eslint-disable-line no-undef
      });
    });
  },
});
