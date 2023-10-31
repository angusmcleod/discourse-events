import buildCategoryRoute from "discourse/routes/build-category-route";
import { calendarRange } from "../../lib/date-utilities";
import { inject as service } from "@ember/service";

export default class DiscoveryCalendarCategoryRoute extends buildCategoryRoute({ filter: "calendar" }) {
  @service siteSettings;

  templateName = 'discovery/calendar'

  beforeModel(transition) {
    const routeName = this.routeName;
    const queryParams = this.paramsFor(routeName);

    if (!queryParams.start || !queryParams.end) {
      const month = moment().month();
      const year = moment().year();
      const { start, end } = calendarRange(month, year);
      this.setProperties({ start, end });
    }

    super.beforeModel(transition);
  }

  setupController(controller, model) {
    const start = this.get("start");
    const end = this.get("end");
    let initialDateRange;

    if (start || end) {
      initialDateRange = {};
      if (start) {
        initialDateRange["start"] = start;
      }
      if (end) {
        initialDateRange["end"] = end;
      }
    }
    // respect discourse-layouts settings
    const global = this.siteSettings.layouts_list_navigation_disabled_global;
    const catGlobal =
      model.category &&
      model.category.get("layouts_list_navigation_disabled_global");
    const showNavigation = !global && !catGlobal;

    controller.setProperties({
      initialDateRange,
      showNavigation
    });

    super.setupController(...arguments);
  }
}
