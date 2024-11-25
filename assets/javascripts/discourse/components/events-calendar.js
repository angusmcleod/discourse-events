import Component from "@ember/component";
import { alias, not, or } from "@ember/object/computed";
import { scheduleOnce } from "@ember/runloop";
import { service } from "@ember/service";
import Category from "discourse/models/category";
import {
  bind,
  default as discourseComputed,
  observes,
  on,
} from "discourse-common/utils/decorators";
import I18n from "I18n";
import {
  calendarDays,
  calendarRange,
  eventsForDay,
} from "../lib/date-utilities";

const RESPONSIVE_BREAKPOINT = 800;
const YEARS = [
  moment().subtract(1, "year").year(),
  moment().year(),
  moment().add(1, "year").year(),
];

export default Component.extend({
  classNameBindings: [":events-calendar", "responsive"],
  showEvents: not("eventsBelow"),
  canSelectDate: alias("eventsBelow"),
  router: service(),
  queryParams: alias("router.currentRoute.queryParams"),
  years: YEARS.map((y) => ({ id: y, name: y })),
  layoutName: "components/events-calendar",
  webcalDocumentationURL: "https://coop.pavilion.tech/t/1447",

  @on("init")
  setup() {
    this._super();
    moment.locale(I18n.locale);

    scheduleOnce("afterRender", this, this.positionCalendar);

    let currentDate = moment().date();
    let currentMonth = moment().month();
    let currentYear = moment().year();

    // get month and year from the date in middle of the event range
    const initialDateRange = this.get("initialDateRange");
    const queryParams = this.get("queryParams");
    let dateRange = {};
    if (initialDateRange) {
      dateRange = initialDateRange;
    }
    if (queryParams.start) {
      dateRange.start = queryParams.start;
    }
    if (queryParams.end) {
      dateRange.end = queryParams.end;
    }

    if (dateRange.start && dateRange.end) {
      const start = moment(dateRange.start);
      const end = moment(dateRange.end);
      const diff = Math.abs(start.diff(end, "days"));
      const middleDay = start.add(diff / 2, "days");
      currentMonth = middleDay.month();
      currentYear = middleDay.year();
    }

    let month = currentMonth;
    let year = currentYear;

    this.setProperties({ currentDate, currentMonth, currentYear, month, year });
  },

  positionCalendar() {
    this.handleResize();
    window.addEventListener("resize", this.handleResize, false);
  },

  @discourseComputed("siteSettings.login_required", "category.read_restricted")
  showNotice(loginRequired, categoryRestricted) {
    return loginRequired || categoryRestricted;
  },

  @on("willDestroy")
  teardown() {
    window.removeEventListener("resize", this.handleResize);
  },

  @bind
  handleResize() {
    if (this._state === "destroying") {
      return;
    }
    this.set("responsiveBreak", window.innerWidth < RESPONSIVE_BREAKPOINT);
  },

  forceResponsive: false,
  responsive: or("forceResponsive", "responsiveBreak", "site.mobileView"),
  showFullTitle: not("responsive"),
  eventsBelow: alias("responsive"),

  @discourseComputed("responsive")
  todayLabel(responsive) {
    return responsive ? null : "events_calendar.today";
  },

  @discourseComputed
  months() {
    return moment
      .localeData()
      .months()
      .map((m, i) => {
        return { id: i, name: m };
      });
  },

  @discourseComputed("currentDate", "currentMonth", "currentYear", "topics.[]")
  dateEvents(currentDate, currentMonth, currentYear, topics) {
    const day = moment().year(currentYear).month(currentMonth);
    return eventsForDay(day.date(currentDate), topics, {
      dateEvents: true,
      siteSettings: this.siteSettings,
    });
  },

  @discourseComputed("currentMonth", "currentYear")
  days(currentMonth, currentYear) {
    const { start, end } = calendarDays(currentMonth, currentYear);
    let days = [];
    for (let day = moment(start); day.isBefore(end); day.add(1, "days")) {
      days.push(moment().year(day.year()).month(day.month()).date(day.date()));
    }
    return days;
  },

  @discourseComputed()
  showSubscription() {
    return !this.site.mobileView;
  },

  transitionToMonth(month, year) {
    const { start, end } = calendarRange(month, year);
    const router = this.get("router");

    if (this.get("loading")) {
      return;
    }
    this.set("loading", true);

    return router
      .transitionTo({
        queryParams: { start, end },
      })
      .then(() => {
        const category = this.get("category");
        let filter = "";

        if (category) {
          filter += `c/${Category.slugFor(category)}/l/`;
        }
        filter += "calendar";

        this.store
          .findFiltered("topicList", {
            filter,
            params: { start, end },
          })
          .then((list) => {
            if (this._state === "destroying") {
              return;
            }

            this.setProperties({
              topics: list.topics,
              currentMonth: month,
              currentYear: year,
              loading: false,
            });
          });
      });
  },

  @observes("month", "year")
  getNewTopics() {
    const currentMonth = this.get("currentMonth");
    const currentYear = this.get("currentYear");
    const month = this.get("month");
    const year = this.get("year");
    if (currentMonth !== month || currentYear !== year) {
      this.transitionToMonth(month, year);
    }
  },

  actions: {
    selectDate(selectedDate, selectedMonth) {
      const month = this.get("month");
      if (month !== selectedMonth) {
        this.set("month", selectedMonth);
      }
      this.set("currentDate", selectedDate);
    },

    today() {
      this.setProperties({
        month: moment().month(),
        year: moment().year(),
        currentDate: moment().date(),
      });
    },

    monthPrevious() {
      let currentMonth = this.get("currentMonth");
      let year = this.get("currentYear");
      let month;

      if (currentMonth === 0) {
        month = 11;
        year = year - 1;
      } else {
        month = currentMonth - 1;
      }

      this.setProperties({ month, year });
    },

    monthNext() {
      let currentMonth = this.get("currentMonth");
      let year = this.get("currentYear");
      let month;

      if (currentMonth === 11) {
        month = 0;
        year = year + 1;
      } else {
        month = currentMonth + 1;
      }

      this.setProperties({ month, year });
    },

    changeSubscription() {},
  },
});
