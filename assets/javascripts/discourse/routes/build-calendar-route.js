import buildCategoryRoute from "discourse/routes/build-category-route";
import buildTopicRoute from "discourse/routes/build-topic-route";
import { calendarRange } from "../lib/date-utilities";

export default function buildCalendarRoute(routeConfig) {
  const klass =
    routeConfig.type === "category"
      ? buildCategoryRoute({ filter: "calendar" })
      : buildTopicRoute("calendar");

  return class extends klass {
    templateName = "discovery/calendar";

    beforeModel() {
      super.beforeModel(...arguments);
      const routeName = this.routeName;
      const queryParams = this.paramsFor(routeName);

      if (!queryParams.start || !queryParams.end) {
        const month = moment().month();
        const year = moment().year();
        const { start, end } = calendarRange(month, year);
        this.setProperties({ start, end });
      }
    }

    setupController() {
      super.setupController(...arguments);
      const start = this.get("start");
      const end = this.get("end");

      if (start || end) {
        let initialDateRange = {};
        if (start) {
          initialDateRange["start"] = start;
        }
        if (end) {
          initialDateRange["end"] = end;
        }

        const controllerName =
          this.routeConfig.type === "category"
            ? "discovery.calendarCategory"
            : "discovery.calendar";
        this.controllerFor(controllerName).setProperties({
          initialDateRange,
        });
      }
    }
  };
}
