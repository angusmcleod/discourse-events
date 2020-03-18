import DatePicker from "discourse/components/date-picker";
import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import loadScript from "discourse/lib/load-script";
import { calendarRange, firstDayOfWeek } from '../lib/date-utilities';

export default DatePicker.extend({
  layoutName: "components/date-picker",
  @on("didInsertElement")
  _loadDatePicker() {
    const input = this.$(".date-picker")[0];
    const container = $("#" + this.get("containerId"))[0];

    loadScript("/javascripts/pikaday.js").then(() => {
      Ember.run.next(() => {
        let default_opts = {
          field: input,
          container: container || this.$()[0],
          bound: container === undefined,
          format: "YYYY-MM-DD",
          firstDay: firstDayOfWeek(),
          i18n: {
            previousMonth: I18n.t("dates.previous_month"),
            nextMonth: I18n.t("dates.next_month"),
            months: moment.months(),
            weekdays: moment.weekdays(),
            weekdaysShort: moment.weekdaysShort()
          },
          onSelect: date => {
            const formattedDate = moment(date).format("YYYY-MM-DD");

            if (this.attrs.onSelect) {
              this.attrs.onSelect(formattedDate);
            }

            if (!this.element || this.isDestroying || this.isDestroyed) return;

            this.set("value", formattedDate);
          }
        };

        this._picker = new Pikaday(_.merge(default_opts, this._opts()));
      });
    });
  }
});