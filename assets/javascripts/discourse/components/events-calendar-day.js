import Component from "@ember/component";
import { action } from "@ember/object";
import { gt } from "@ember/object/computed";
import {
  default as discourseComputed,
  on,
} from "discourse-common/utils/decorators";
import { eventsForDay } from "../lib/date-utilities";

const MAX_EVENTS = 3;

export default Component.extend({
  classNameBindings: [":day", "classes", "differentMonth"],
  attributeBindings: ["day:data-day"],
  hidden: 0,
  hasHidden: gt("hidden", 0),

  @discourseComputed("month", "currentMonth")
  differentMonth(month, currentMonth) {
    return month !== currentMonth;
  },

  @on("init")
  setEvents() {
    let events = this.get("allEvents");

    if (events.length) {
      let hidden = events.splice(MAX_EVENTS);

      if (hidden.length) {
        this.set("hidden", hidden.length);
      }
    }

    this.set("events", events);
  },

  @action
  onShowHiddenEvents() {
    this.set("expanded", true);
  },

  @discourseComputed("day", "topics.[]", "expanded", "rowIndex")
  allEvents(day, topics, expanded, rowIndex) {
    return eventsForDay(day, topics, {
      rowIndex,
      expanded,
      siteSettings: this.siteSettings,
    });
  },

  @discourseComputed("index")
  rowIndex(index) {
    return index % 7;
  },

  click() {
    const canSelectDate = this.get("canSelectDate");
    if (canSelectDate) {
      const date = this.get("date");
      const month = this.get("month");
      this.selectDate(date, month);
    }
  },

  @discourseComputed("index")
  date() {
    const day = this.get("day");
    return day.date();
  },

  @discourseComputed("index")
  month() {
    const day = this.get("day");
    return day.month();
  },

  @discourseComputed("day", "currentDate", "currentMonth", "responsive")
  classes(day, currentDate, currentMonth, responsive) {
    let classes = "";
    if (day.isSame(moment(), "day")) {
      classes += "today ";
    }
    if (
      responsive &&
      day.isSame(moment().month(currentMonth).date(currentDate), "day")
    ) {
      classes += "selected ";
    }
    return classes;
  },
});
