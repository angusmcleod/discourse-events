import { getOwner } from "@ember/application";
import I18n from "I18n";

export default {
  shouldRender(_, ctx) {
    return ctx.siteSettings.events_enabled;
  },

  setupComponent(_, component) {
    const controller = getOwner(this).lookup(
      "controller:preferences/interface"
    );

    moment.locale(I18n.locale);
    const data = moment.localeData();
    const weekdaysRaw = data.weekdays();
    let weekdaysAvailable = Object.keys(weekdaysRaw).reduce((weekdays, day) => {
      if (day === "6" || day <= "1") {
        weekdays.push({
          id: Number(day),
          name: weekdaysRaw[day],
        });
      }
      return weekdays;
    }, []);

    // move saturday to the start
    weekdaysAvailable.unshift(weekdaysAvailable.pop());

    component.setProperties({
      weekdaysAvailable,
      controller,
    });

    if (!controller.get("model.custom_fields.calendar_first_day_week")) {
      const userFirst = controller.get("model.calendar_first_day_week");
      const localeFirst = data.firstDayOfWeek();
      const first =
        !isNaN(parseFloat(userFirst)) && isFinite(userFirst)
          ? userFirst
          : localeFirst;
      controller.set("model.custom_fields.calendar_first_day_week", first);
    }

    // Update the custom field when the user changes their preference
    component.addObserver(
      "controller.model.custom_fields.calendar_first_day_week",
      function () {
        const newFirstDay = controller.get(
          "model.custom_fields.calendar_first_day_week"
        );
        controller.set("model.calendar_first_day_week", newFirstDay);
      }
    );
  },
};
