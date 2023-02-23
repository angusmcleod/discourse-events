import {
  default as discourseComputed,
  observes,
  on,
} from "discourse-common/utils/decorators";
import { eventsForDay } from "../lib/date-utilities";
import { gt } from "@ember/object/computed";
import { bind } from "@ember/runloop";
import Component from "@ember/component";
import { htmlSafe } from "@ember/template";

const MAX_EVENTS = 4;

export default Component.extend({
  classNameBindings: [":day", "classes", "differentMonth"],
  attributeBindings: ["day:data-day"],
  hidden: 0,
  hasHidden: gt("hidden", 0),

  @discourseComputed("date", "month", "expandedDate")
  expanded(date, month, expandedDate) {
    return `${month}.${date}` === expandedDate;
  },

  @discourseComputed("month", "currentMonth")
  differentMonth(month, currentMonth) {
    return month !== currentMonth;
  },

  @on("init")
  @observes("expanded")
  setEvents() {
    const expanded = this.get("expanded");
    const allEvents = this.get("allEvents");
    let events = $.extend([], allEvents);

    if (events.length && !expanded) {
      let hidden = events.splice(MAX_EVENTS);

      if (hidden.length) {
        this.set("hidden", hidden.length);
      }
    } else {
      this.set("hidden", 0);
    }

    this.set("events", events);
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

  didInsertElement() {
    this.set("clickHandler", bind(this, this.documentClick));
    $(document).on("click", this.get("clickHandler"));
  },

  willDestroyElement() {
    $(document).off("click", this.get("clickHandler"));
  },

  documentClick(event) {
    if (
      !event.target.closest(
        `.events-calendar-body .day[data-day='${this.day}']`
      )
    ) {
      this.clickOutside();
    } else {
      this.click();
    }
  },

  clickOutside() {
    if (this.get("expanded")) {
      this.get("setExpandedDate")(null);
    }
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

  @discourseComputed(
    "day",
    "currentDate",
    "currentMonth",
    "expanded",
    "responsive"
  )
  classes(day, currentDate, currentMonth, expanded, responsive) {
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
    if (expanded) {
      classes += "expanded";
    }
    return classes;
  },

  @discourseComputed("expanded")
  containerStyle(expanded) {
    let style = "";

    if (expanded) {
      const offsetLeft = this.element.offsetLeft;
      const offsetTop = this.element.offsetTop;
      const windowWidth = $(window).width();
      const windowHeight = $(window).height();

      if (offsetLeft > windowWidth / 2) {
        style += "right:0;";
      } else {
        style += "left:0;";
      }

      if (offsetTop > windowHeight / 2) {
        style += "bottom:0;";
      } else {
        style += "top:0;";
      }
    }

    return htmlSafe(style);
  },
});
