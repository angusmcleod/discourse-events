import { renderIcon } from "discourse-common/lib/icon-library";
import Site from "discourse/models/site";
import { htmlSafe } from "@ember/template";
import I18n from "I18n";
import User from "discourse/models/user";
import moment from "moment-timezone"; // Assuming moment-timezone is imported

const FORM_DATE_FORMAT = "YYYY-MM-DD";
const FORM_TIME_FORMAT = "HH:mm";
const RANGE_FORMAT = "YYYY-MM-DD";
const DEFAULT_TIMEZONE = moment.tz.guess();

function getDefaultTimezone(args) {
  return args.siteSettings.events_timezone_default || DEFAULT_TIMEZONE;
}

function getTimezone(event = null, args = {}) {
  let timezone = getDefaultTimezone(args);
  if (event && event.timezone) {
    const display = args.siteSettings.events_timezone_display;
    if (args.useEventTimezone || display === "event" || (display === "different" && event.timezone !== timezone)) {
      timezone = event.timezone;
    }
  }
  return timezone;
}

function includeTimezone(event = null, args = {}) {
  if (!event) return false;
  if (args.useEventTimezone && event.timezone) return true;
  if (args.list === "true") return args.siteSettings.events_timezone_include_in_topic_list;
  if (args.topic === "true") return args.siteSettings.events_timezone_include_in_topic;
  return false;
}

function isAllDay(event) {
  if (event.all_day === true || event.all_day === "true") return true;

  const start = moment(event.start);
  const end = moment(event.end);
  return start.hour() === 0 && start.minute() === 0 && end.hour() === 23 && end.minute() === 59;
}

function nextInterval() {
  const rounding = 30 * 60 * 1000;
  return moment(Math.ceil(+moment() / rounding) * rounding);
}

function uriDateTimes(event) {
  const format = event.all_day ? "YYYYMMDD" : "YYYYMMDDTHHmmss";
  const rawStart = event.start;
  const start = moment(rawStart).local().format(format);
  let rawEnd = moment(event.end || event.start);
  if (event.all_day) rawEnd = moment(rawEnd).add(1, "days");
  const end = moment(rawEnd).local().format(format);
  return { start, end };
}

function googleUri(params) {
  const { start, end } = uriDateTimes(params.event);
  return `https://www.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(params.title)}&dates=${start}/${end}&details=${params.details || I18n.t("add_to_calendar.default_details", { url: params.url })}&location=${params.location}&sf=true&output=xml`;
}

function icsUri(params) {
  const { start, end } = uriDateTimes(params.event);
  return encodeURI(`data:text/calendar;charset=utf8,${[
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "BEGIN:VEVENT",
    `URL:${document.URL}`,
    `DTSTART:${start}`,
    `DTEND:${end}`,
    `SUMMARY:${params.title}`,
    `DESCRIPTION:${params.details || ""}`,
    `LOCATION:${params.location || ""}`,
    "END:VEVENT",
    "END:VCALENDAR"
  ].join("\n")}`);
}

function allDayAttrs(attrs, topic, startIsSame, endIsSame, isBetween) {
  attrs.classes += " all-day";
  attrs.allDay = true;
  if (startIsSame) attrs.classes += " start";
  if (endIsSame) attrs.classes += " end";
  if (isBetween) attrs.classes += " is-between";
  if (!endIsSame || isBetween) attrs.classes += " multi";
  if (topic.category) attrs.listStyle += `background-color: #${topic.category.color};`;
  return attrs;
}

function eventCalculations(day, start, end) {
  const date = day.date();
  const month = day.month();
  const year = day.year();
  const startDate = start.date();
  const startMonth = start.month();
  const startYear = start.year();

  const startIsSame = date === startDate && month === startMonth && year === startYear;
  let endIsSame = false;
  let isBetween = false;
  let daysLeft = 1;

  if (end) {
    const endDate = end.date();
    const endMonth = end.month();
    const endYear = end.year();
    endIsSame = end && date === endDate && month === endMonth && year === endYear;

    const startIsBefore = year > startYear || (year === startYear && (month > startMonth || (month === startMonth && date > startDate)));
    const endIsAfter = year < endYear || (year === endYear && (month < endMonth || (month === endMonth && date < endDate)));
    isBetween = startIsBefore && endIsAfter;

    daysLeft = month === endMonth ? endDate - date + 1 : moment(end).diff(moment(day), "days");
  }

  return { startIsSame, endIsSame, isBetween, daysLeft };
}

const allowedFirstDays = [6, 0, 1]; // Saturday, Sunday, Monday
function firstDayOfWeek() {
  const user = User.current();
  return user && allowedFirstDays.includes(user.calendar_first_day_week) ? user.calendar_first_day_week : moment().weekday(0).day();
}

function calendarDays(month, year) {
  const firstDayMonth = moment().year(year).month(month).date(1);
  const firstDayWeek = firstDayOfWeek();

  let start;
  let diff;
  if (firstDayMonth.day() >= firstDayWeek) {
    diff = firstDayMonth.day() - firstDayWeek;
    start = firstDayMonth.day(firstDayWeek);
  } else {
    diff = firstDayWeek === 1 ? 6 : firstDayMonth.day() + 1;
    start = firstDayMonth.subtract(diff, "days");
  }

  const count = diff + moment().year(year).month(month).daysInMonth() > 35 ? 42 : 35;
  const end = moment(start).add(count, "days");

  return { start, end };
}

function calendarRange(month, year) {
  const { start, end } = calendarDays(month, year);
  return { start: start.format(RANGE_FORMAT), end: end.format(RANGE_FORMAT) };
}

function compileDateTime(params, type) {
  const dateTime = moment(params[`${type}Date`]);
  dateTime.tz(params.timezone);
  return dateTime
    .hour(params.allDay ? 0 : moment(params[`${type}Time`], "HH:mm").hour())
    .minute(params.allDay ? 0 : moment(params[`${type}Time`], "HH:mm").minute())
    .second(0)
    .millisecond(0)
    .toISOString();
}

function compileEvent(params) {
  if (!params.startDate) return null;

  const event = {
    timezone: params.timezone,
    all_day: params.allDay,
    start: compileDateTime(params, "start")
  };

  if (params.endEnabled) {
    event.end = compileDateTime(params, "end");
  }

  if (params.rsvpEnabled) {
    event.rsvp = true;
    if (params.goingMax) event.going_max = params.goingMax;
    if (params.usersGoing) event.going = params.usersGoing;
  }

  return event;
}

function eventLabel(event, args = {}) {
  const { siteSettings = {} } = args;
  const icon = siteSettings.events_event_label_icon;
  const standardFormat = siteSettings.events_event_label_format;
  const listFormat = siteSettings.events_event_label_short_format;
  const listOnlyStart = siteSettings.events_event_label_short_only_start;
  const format = args.list ? listFormat : standardFormat;

  let label = renderIcon("string", icon, { class: format ? "" : "no-date" });
  if (args.noText) return label;

  const { start, end, allDay, timezone } = setupEvent(event, args);

  if (format) {
    let dateString = start.format(allDay ? format.split(",")[0] : format);
    if (event.end && (!args.list || !listOnlyStart)) {
      const diffDay = start.month() !== end.month() || start.date() !== end.date();
      if (!allDay || diffDay) {
        dateString += ` – ${end.format(diffDay || allDay ? format : format.split(",").pop())}`;
      }
    }
    if (timezone && includeTimezone(event, args)) {
      dateString += `, ${timezoneLabel(timezone, args)}`;
    }
    label += `<span class="date">${dateString}</span>`;
  } else {
    label += '<span class="date no-date"></span>';
  }

  if (args.showRsvp && event.rsvp) {
    label += `<span class="dot">&middot;</span><span class="rsvp">${I18n.t("add_event.rsvp_enabled_label")}</span>`;
    if (event.going_max) {
      label += `<span class="dot">&middot;</span><span class="going-max">${I18n.t("add_event.going_max_label", { goingMax: event.going_max })}</span>`;
    }
  }

  return label;
}

function setupEvent(event, args = {}) {
  let start, end, allDay, timezone;
  if (event) {
    start = moment(event.start);
    allDay = isAllDay(event);
    if (event.end) {
      end = moment(event.end);
    }
    if (!allDay) {
      timezone = getTimezone(event, args);
      if (timezone) {
        start = start.tz(timezone);
        if (event.end) end = end.tz(timezone);
      }
    }
  }
  return { start, end, allDay, timezone };
}

function timezoneLabel(tz, args = {}) {
  const formatSetting = args.siteSettings.events_timezone_format;
  if (formatSetting) return moment.tz(tz).format(formatSetting);

  const timezones = Site.currentProp("event_timezones");
  const railsFormatSetting = args.siteSettings.events_timezone_rails_format;
  if (timezones && railsFormatSetting) {
    const standard = timezones.find(tzObj => tzObj.value === tz);
    if (standard) return standard.name;
  }

  const offset = moment.tz(tz).format("Z");
  const name = tz.replace("_", "");
  return `(${offset}) ${name}`;
}

function setupEventForm(event, args = {}) {
  const { start, end, allDay, timezone } = setupEvent(event, { ...args, useEventTimezone: true });
  const props = { timezone: timezone || args.siteSettings.events_timezone_default };

  if (allDay) {
    props.allDay = true;
    props.startDate = start.format(FORM_DATE_FORMAT);
    props.endDate = end ? end.format(FORM_DATE_FORMAT) : props.startDate;
    props.endEnabled = moment(props.endDate).isAfter(props.startDate, "day");
  } else if (start) {
    props.startDate = start.format(FORM_DATE_FORMAT);
    props.startTime = start.format(FORM_TIME_FORMAT);
    if (end) {
      props.endDate = end.format(FORM_DATE_FORMAT);
      props.endTime = end.format(FORM_TIME_FORMAT);
      props.endEnabled = true;
    }
  } else {
    props.startDate = moment().format(FORM_DATE_FORMAT);
    props.startTime = nextInterval().format(FORM_TIME_FORMAT);
  }

  if (event && event.rsvp) {
    props.rsvpEnabled = true;
    if (event.going_max) props.goingMax = event.going_max;
    if (event.going) props.usersGoing = event.going;
  }

  return props;
}

function eventsForDay(day, topics, args = {}) {
  const events = topics.filter(t => t.event);
  const fullWidth = args.dateEvents || args.expanded;
  let blockIndex = 0;

  return events.reduce((dayEvents, topic) => {
    const { start, end, allDay, multiDay } = setupEvent(topic.event, args);
    const { startIsSame, endIsSame, isBetween, daysLeft } = eventCalculations(day, start, end);
    if (startIsSame || endIsSame || isBetween) {
      let attrs = { topic, classes: "event", listStyle: "" };
      if (fullWidth) attrs.classes += " full-width";
      const blockStyle = allDay || multiDay;
      if (blockStyle) {
        attrs = allDayAttrs(attrs, topic, startIsSame, endIsSame, isBetween);
        if (topic.event.blockIndex === undefined) topic.event.blockIndex = blockIndex++;
      } else if (topic.category) {
        attrs.dotStyle = htmlSafe(`color: #${topic.category.color}`);
      }
      if (!allDay && (!multiDay || startIsSame)) {
        attrs.time = start.format(args.siteSettings.events_event_time_calendar_format);
      }
      if (startIsSame || fullWidth || args.rowIndex === 0) {
        attrs.title = topic.title;
        if ((multiDay || allDay) && !fullWidth) {
          const remainingInRow = 7 - args.rowIndex;
          const daysInRow = daysLeft >= remainingInRow ? remainingInRow : daysLeft;
          const buffer = 20 + (attrs.time ? 55 : 0);
          attrs.titleStyle = htmlSafe(`width:calc((100% * ${daysInRow}) - ${buffer}px); background-color: #${topic.category.color};`);
        }
      }
      attrs.listStyle = htmlSafe(attrs.listStyle);
      if (blockStyle) {
        const diff = topic.event.blockIndex - dayEvents.length;
        for (let i = 0; i < diff; i++) {
          dayEvents.push({ allDay: true, empty: true, classes: "empty" });
          blockIndex++;
        }
      }
      const insertAt = blockStyle ? topic.event.blockIndex : dayEvents.length;
      const replace = 0;
      const emptyIndexes = [];
      dayEvents.forEach((e, i) => {
        if (e.empty) emptyIndexes.push(i);
      });
      if ((startIsSame && emptyIndexes.length) || topic.event.backfill) {
        attrs.backfill = true;
        const backfillIndex = emptyIndexes.includes(topic.event.blockIndex) ? topic.event.blockIndex : emptyIndexes[0];
        if (blockStyle) {
          insertAt = topic.event.blockIndex = backfillIndex;
          topic.event.backfill = true;
        } else {
          insertAt = backfillIndex;
        }
        replace = 1;
        blockIndex--;
      }
      dayEvents.splice(insertAt, replace, attrs);
    }
    return dayEvents;
  }, []);
}

export {
  eventLabel,
  googleUri,
  icsUri,
  eventsForDay,
  setupEvent,
  compileEvent,
  setupEventForm,
  timezoneLabel,
  firstDayOfWeek,
  calendarDays,
  calendarRange,
  getTimezone,
  FORM_TIME_FORMAT,
  nextInterval,
  eventCalculations,
};
