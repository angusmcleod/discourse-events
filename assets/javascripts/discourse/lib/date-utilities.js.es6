import { renderIcon } from "discourse-common/lib/icon-library";

let isAllDay = function(event) {
  if (event['all_day'] === true || event['all_day'] === 'true') return true;

  // legacy check for events pre-addition of 'all_day' attribute
  const start = moment(event['start']);
  const end = moment(event['end']);
  const startIsDayStart = start.hour() === 0 && start.minute() === 0;
  const endIsDayEnd = end.hour() === 23 && end.minute() === 59;

  return startIsDayStart && endIsDayEnd;
};

let getDefaultTimezone = function() {
  const setting = Discourse.SiteSettings.events_timezone_default;
  const user = moment.tz.guess();
  return setting ? setting : user;
}

let getTimezone = function(event = null, args = {}) {
  let timezone = getDefaultTimezone();

  if (event && event['timezone']) {
    const display = Discourse.SiteSettings.events_timezone_display;

    if (args.useEventTimezone ||
        display === 'event' ||
        (display === 'different' && event['timezone'] !== timezone)) {
      timezone = event['timezone'];
    }
  }

  return timezone;
}

let includeTimezone = function(event = null, args = {}) {
  if (!event) return false;

  if (args.useEventTimezone && event['timezone']) return true;

  const includeInTopicList = Discourse.SiteSettings.events_timezone_include_in_topic_list;
  if (args.list === 'true') return includeInTopicList;

  const includeInTopic = Discourse.SiteSettings.events_timezone_include_in_topic;
  if (args.topic === 'true') return includeInTopic;

  return false;
}

let setupEvent = function(event, args = {}) {
  let start;
  let end;
  let allDay;
  let multiDay;
  let timezone;

  if (event) {
    start = moment(event['start']);
    allDay = isAllDay(event);

    if (event['end']) {
      end = moment(event['end']);
      multiDay = (end.date() > start.date()) || (end.month() > start.month());
    }

    if (!allDay) {
      timezone = getTimezone(event, args);

      if (timezone) {
        start = start.tz(timezone);

        if (event['end']) {
          end = end.tz(timezone);
        }
      }
    }
  }

  return { start, end, allDay, multiDay, timezone };
};

let timezoneLabel = function(tz) {
  const siteSettings = Discourse.SiteSettings;

  // if there is a custom moment.js format use that
  const formatSetting = siteSettings.events_timezone_format;
  if (formatSetting) {
    return moment.tz(tz).format(formatSetting);
  }

  // if the Rails format setting is enabled,
  // and the zone has a Rails standard format, use that
  const timezones = Discourse.Site.currentProp('event_timezones');
  const railsFormatSetting = siteSettings.events_timezone_rails_format;
  if (timezones && railsFormatSetting) {
    const standard = timezones.find(tzObj => tzObj.value === tz);
    if (standard) return standard.name;
  }

  // fallback to IANA name if there is no custom format and
  // Rails format is disabled or zone is not part of the Rails standard set.
  const offset = moment.tz(tz).format('Z');
  let raw = tz;
  let name = raw.replace('_', '');
  return`(${offset}) ${name}`;
};

let eventLabel = function(event, args = {}) {
  const icon = Discourse.SiteSettings.events_event_label_icon;
  const standardFormat = Discourse.SiteSettings.events_event_label_format;
  const listFormat = Discourse.SiteSettings.events_event_label_short_format;
  const listOnlyStart = Discourse.SiteSettings.events_event_label_short_only_start;
  let format = args.list ? listFormat : standardFormat;

  let iconClass = '';
  if (!format) iconClass += 'no-date';
  let label = renderIcon("string", icon, { class: iconClass });

  if (!args.noText) {
    const { start, end, allDay, multiDay, timezone } = setupEvent(event, args);

    let dateString = '';
    let dateClass = 'date';

    if (format) {
      let formatArr = format.split(',');
      if (allDay) format = formatArr[0];
      dateString = start.format(format);

      if (event['end'] && (!args.list || !listOnlyStart)) {
        const diffDay = start.month() !== end.month() || start.date() !== end.date();

        if (!allDay || diffDay) {
          const endFormat = (diffDay || allDay) ? format : formatArr[formatArr.length - 1];
          dateString += ` – ${end.format(endFormat)}`;
        }
      }

      if (timezone && includeTimezone(event, args)) {
        dateString += `, ${timezoneLabel(timezone)}`;
      }
    } else {
      dateClass += ' no-date';
    }

    label += `<span class="${dateClass}">${dateString}</span>`;

    if (args.showRsvp) {
      if (event.rsvp) {
        label += '<span class="dot">&middot;</span>'
        label += `<span class="rsvp">${I18n.t('add_event.rsvp_enabled_label')}</span>`

        if (event.going_max) {
          label += '<span class="dot">&middot;</span>'
          label += `<span class="going-max">${I18n.t('add_event.going_max_label', { goingMax: event.going_max })}</span>`
        }
      }
    }
  }

  return label;
};

let uriDateTimes = function(event) {
  let format = event.all_day ? "YYYYMMDD" : "YYYYMMDDTHHmmss";
  let rawStart = event.start;
  let start = moment(rawStart).local().format(format);
  let rawEnd = moment(event.end || event.start);
  if (event.all_day) rawEnd = moment(rawEnd).add(1, 'days');
  let end = moment(rawEnd).local().format(format);
  return { start, end };
};

let googleUri = function(params) {
  let href = "https://www.google.com/calendar/render?action=TEMPLATE";

  if (params.title) {
    href += `&text=${encodeURIComponent(params.title)}`;
  }

  let { start, end } = uriDateTimes(params.event);
  href += `&dates=${start}/${end}`;

  href += `&details=${params.details || I18n.t('add_to_calendar.default_details', { url: params.url })}`;

  if (params.location) {
    href += `&location=${params.location}`;
  }

  href += "&sf=true&output=xml";

  return href;
};

let icsUri = function(params) {
  let url = document.URL;
  let title = params.title;
  let details = params.details || '';
  let location = params.location || '';
  let { start, end } = uriDateTimes(params.event);

  return encodeURI(
    'data:text/calendar;charset=utf8,' + [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'BEGIN:VEVENT',
      'URL:' + url,
      'DTSTART:' + start,
      'DTEND:' + end,
      'SUMMARY:' + title,
      'DESCRIPTION:' + details,
      'LOCATION:' + location,
      'END:VEVENT',
      'END:VCALENDAR'
    ].join('\n')
  );
};

let allDayAttrs = function(attrs, topic, startIsSame, endIsSame, isBetween) {
  attrs['classes'] += ' all-day';
  attrs['allDay'] = true;

  if (startIsSame) {
    attrs['classes'] += ' start';
  }

  if (endIsSame) {
    attrs['classes'] += ' end';
  }

  if (isBetween) {
    attrs['classes'] += ' is-between';
  }

  if (!endIsSame || isBetween) {
    attrs['classes'] += ' multi';
  }

  if (topic.category) {
    attrs['listStyle'] += `background-color: #${topic.category.color};`;
  }

  return attrs;
};

let eventCalculations = function(day, start, end) {
  // equivalent momentjs comparisons dont work well with all-day timezone handling
  const date = day.date();
  const month = day.month();
  const year = day.year();
  const startDate = start.date();
  const startMonth = start.month();
  const startYear = start.year();

  const startIsSame = (date === startDate) && (month === startMonth) && (year === startYear);
  let endIsSame = false;
  let isBetween = false;
  let daysLeft = 1;

  if (end) {
    const endDate = end.date();
    const endMonth = end.month();
    const endYear = end.year();
    endIsSame = end && (date === endDate) && (month === endMonth) && (year === endYear);

    const startIsBefore = (year > startYear) || ((year === startYear) && ((month > startMonth) || (month === startMonth && date > startDate)));
    const endIsAfter = (year < endYear) || ((year === endYear) && ((month < endMonth) || (month === endMonth && date < endDate)));
    isBetween = startIsBefore && endIsAfter;

    daysLeft = month === endMonth ? endDate - date + 1 : moment(end).diff(moment(day), 'days');
  }

  return { startIsSame, endIsSame, isBetween, daysLeft };
};

let eventsForDay = function(day, topics, args = {}) {
  const events = topics.filter((t) => t.event);
  const fullWidth = args.dateEvents || args.expanded;
  let blockIndex = 0;

  return events.reduce((dayEvents, topic) => {
    const { start, end, allDay, multiDay } = setupEvent(topic.event);
    const { startIsSame, endIsSame, isBetween, daysLeft } = eventCalculations(day, start, end);
    const onThisDay = startIsSame || endIsSame || isBetween;

    if (onThisDay) {
      let attrs = {
        topic,
        classes: 'event',
        listStyle: ''
      };

      if (fullWidth) {
        attrs['classes'] += ' full-width';
      }

      const blockStyle = allDay || multiDay;

      if (blockStyle) {
        attrs = allDayAttrs(attrs, topic, startIsSame, endIsSame, isBetween);

        if (topic.event.blockIndex === undefined) {
          topic.event.blockIndex = blockIndex;
        }
        blockIndex ++;
      } else if (topic.category) {
        attrs['dotStyle'] = Ember.String.htmlSafe(`color: #${topic.category.color}`);
      }

      if (!allDay && (!multiDay || startIsSame)) {
        const timeFormat = Discourse.SiteSettings.events_event_time_calendar_format;
        attrs['time'] = start.format(timeFormat);
      }

      if (startIsSame || fullWidth || args.rowIndex === 0) {
        attrs['title'] = topic.title;

        if ((multiDay || allDay) && !fullWidth) {
          let remainingInRow = 7 - args.rowIndex;
          let daysInRow = daysLeft >= remainingInRow ? remainingInRow : daysLeft;
          let buffer = 20;
          if (attrs['time']) buffer += 55;
          let tStyle = `width:calc((100%*${daysInRow}) - ${buffer}px);background-color:#${topic.category.color};`;
          attrs['titleStyle'] = Ember.String.htmlSafe(tStyle);
        }
      }

      attrs['listStyle'] = Ember.String.htmlSafe(attrs['listStyle']);

      // Add placeholders if necessary
      if (blockStyle) {
        let diff = topic.event.blockIndex - dayEvents.length;
        if (diff > 0) {
          for (let i=0; i<diff; ++i) {
            dayEvents.push({ allDay: true, empty: true, classes: "empty" });
            blockIndex ++;
          }
        }
      }

      let insertAt = blockStyle ? topic.event.blockIndex : dayEvents.length;
      let replace = 0;

      // backfill when possible
      let emptyIndexes = [];
      dayEvents.forEach((e, i) => {
        if (e.empty) emptyIndexes.push(i);
      });
      if ((startIsSame && emptyIndexes.length) || topic.event.backfill)  {
        attrs['backfill'] = true;
        let backfillIndex = emptyIndexes.indexOf(topic.event.blockIndex) > -1 ?
                            topic.event.blockIndex : emptyIndexes[0];
        if (blockStyle) {
          insertAt = topic.event.blockIndex = backfillIndex;
          topic.event.backfill = true;
        } else {
          insertAt = backfillIndex;
        }

        replace = 1;
        blockIndex --;
      }

      dayEvents.splice(insertAt, replace, attrs);
    }

    return dayEvents;
  }, []);
};

const allowedFirstDays = [6, 0, 1]; // Saturday, Sunday, Monday
let firstDayOfWeek = function() {
  const user = Discourse.User.current();
  return user && allowedFirstDays.indexOf(user.calendar_first_day_week) > -1 ?
         user.calendar_first_day_week : moment().weekday(0).day();
};

let calendarDays = function(month, year) {
  const firstDayMonth = moment().year(year).month(month).date(1);
  const firstDayWeek = firstDayOfWeek();

  let start;
  let diff;
  if (firstDayMonth.day() >= firstDayWeek) {
    diff = firstDayMonth.day() - firstDayWeek;
    start = firstDayMonth.day(firstDayWeek);
  } else {
    if (firstDayWeek === 1) {
      // firstDayMonth has to be 0, i.e. Sunday
      diff = 6;
    } else {
      // islamic calendar starts on 6, i.e. Saturday
      diff = firstDayMonth.day() + 1;
    }
    start = firstDayMonth.subtract(diff, 'days');
  }

  let count = 35;
  if ((diff + moment().year(year).month(month).daysInMonth()) > 35) count = 42;

  const end = moment(start).add(count, 'days');

  return { start, end };
};

const RANGE_FORMAT = 'YYYY-MM-DD';

let calendarRange = function(month, year) {
  const { start, end } = calendarDays(month, year);
  return {
    start: start.format(RANGE_FORMAT),
    end: end.format(RANGE_FORMAT)
  };
};

export { eventLabel, googleUri, icsUri, eventsForDay, setupEvent, timezoneLabel, firstDayOfWeek, calendarDays, calendarRange, getTimezone };
