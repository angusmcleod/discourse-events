let isAllDay = function(event) {
  if (event['all_day']) return true;

  // legacy check for events pre-addition of 'all_day' attribute
  const start = moment(event['start']);
  const end = moment(event['end']);
  const startIsDayStart = start.hour() === 0 && start.minute() === 0;
  const endIsDayEnd = end.hour() === 23 && end.minute() === 59;
  return startIsDayStart && endIsDayEnd;
};

let setupEvent = function(event, args = {}) {
  let start;
  let end;
  let allDay;

  if (event) {
    start = moment(event['start']);

    if (event['end']) {
      end = moment(event['end']);
      allDay = isAllDay(event);
    }

    if (event['timezone'] && (allDay || !args.displayInUserTimezone)) {
      start = start.tz(event['timezone']);
      if (event['end']) {
        end = end.tz(event['timezone']);
      }
    }
  }

  return { start, end, allDay };
};

let timezoneLabel = function(timezone) {
  const offset = moment.tz(timezone).format('Z');
  let raw = timezone;
  const nameArr = raw.split('/');
  if (nameArr.length > 1) {
    raw = nameArr[1];
  }
  let name = raw.replace('_', '');
  return`(${offset}) ${name}`;
};

let eventLabel = function(event, args = {}) {
  const icon = Discourse.SiteSettings.events_event_label_icon;
  const longFormat = Discourse.SiteSettings.events_event_label_format;
  const shortFormat = Discourse.SiteSettings.events_event_label_short_format;
  const shortOnlyStart = Discourse.SiteSettings.events_event_label_short_only_start;

  let label = `<i class='fa fa-${icon}'></i>`;

  if (!args.mobile) {
    const { start, end, allDay } = setupEvent(event, { displayInUserTimezone: args.displayInUserTimezone });

    let format = args.short ? shortFormat : longFormat;
    let formatArr = format.split(',');
    if (allDay) format = formatArr[0];
    let dateString = start.format(format);

    if (event['end'] && (!args.short || !shortOnlyStart)) {
      const diffDay = start.date() !== end.date();
      if (!allDay || diffDay) {
        const endFormat = (diffDay || allDay) ? format : formatArr[formatArr.length - 1];
        dateString += ` – ${end.format(endFormat)}`;
      }
    }

    let timezone = null;
    const forceTimezone = Discourse.SiteSettings.events_event_label_include_timezone;
    if (forceTimezone) {
      timezone = event['timezone'] || moment.tz.guess();
    }
    if (args.showTimezoneIfDifferent && event['timezone'] && event['timezone'] !== moment.tz.guess()) {
      timezone = event['timezone'];
    }
    if (timezone) dateString += `, ${timezoneLabel(timezone)}`;

    label += `<span>${dateString}</span>`;
  }

  return label;
};

let utcDateTime = function(dateTime) {
  return moment.parseZone(dateTime).utc().format().replace(/-|:|\.\d\d\d/g,"");
};

let googleUri = function(params) {
  let href = "https://www.google.com/calendar/render?action=TEMPLATE";
  if (params.title) {
    href += `&text=${params.title.replace(/ /g,'+').replace(/[^\w+]+/g,'')}`;
  }
  href += `&dates=${utcDateTime(params.event.start)}/${utcDateTime(params.event.end)}`;
  href += `&details=${params.details || I18n.t('add_to_calendar.default_details', {url: params.url})}`;
  if (params.location) {
    href += `&location=${params.location}`;
  }
  href += "&sf=true&output=xml";
  return href;
};

let icsUri = function(params) {
  return encodeURI(
    'data:text/calendar;charset=utf8,' + [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'BEGIN:VEVENT',
      'URL:' + document.URL,
      'DTSTART:' + (utcDateTime(params.event.start) || ''),
      'DTEND:' + (utcDateTime(params.event.end) || ''),
      'SUMMARY:' + (params.title || ''),
      'DESCRIPTION:' + (params.details || ''),
      'LOCATION:' + (params.location || ''),
      'END:VEVENT',
      'END:VCALENDAR'
    ].join('\n'));
};

let allDayAttrs = function(attrs, topic) {
  attrs['classes'] = 'all-day';
  attrs['allDay'] = true;

  if (topic.category) {
    attrs['listStyle'] += `background-color: #${topic.category.color};`;
  }

  return attrs;
};

let allDayPrevious = false;
let eventsForDay = function(day, topics, args = {}) {
  let allDayCount = 0;

  return topics.reduce((filtered, topic) => {
    if (topic.event) {
      const { start, end, allDay } = setupEvent(topic.event);

      // equivalent momentjs comparisons dont work well with all-day timezone handling
      const date = day.date();
      const month = day.month();
      const startDate = start.date();
      const startMonth = start.month();
      const startIsSame = date === startDate && month === startMonth;
      const endIsSame = end && (date === end.date()) && (month === end.month());
      const isBetween = end && (month === startMonth || month === end.month()) && (date > startDate) && (date < end.date());

      let attrs = {
        topicId: topic.id,
        listStyle: ''
      };

      if (startIsSame) {
        if (allDay) {
          attrs = allDayAttrs(attrs, topic);
        } else {
          attrs['time'] = moment(topic.event.start).format('h:mm a');

          if (end && !endIsSame) {
            attrs = allDayAttrs(attrs, topic);
          } else if (topic.category) {
            attrs['dotStyle'] = Ember.String.htmlSafe(`color: #${topic.category.color}`);
          }
        }

        attrs['listStyle'] = Ember.String.htmlSafe(attrs['listStyle']);
        attrs['title'] = topic.title;

        filtered.push(attrs);
      } else if (endIsSame || isBetween) {
        allDayCount ++;
        if (!topic.event.allDayIndex) topic.event.allDayIndex = allDayCount;
        if (!args.dateEvents && !allDayPrevious && (topic.event.allDayIndex !== allDayCount)) {
          let difference = topic.event.allDayIndex - allDayCount;
          attrs['listStyle'] += `margin-top: ${difference * 22}px;`;
        }
        allDayPrevious = true;

        attrs = allDayAttrs(attrs, topic);

        if (args.dateEvents || args.expanded || args.firstDay)   {
          attrs['title'] = topic.title;
        }

        attrs['listStyle'] = Ember.String.htmlSafe(attrs['listStyle']);

        filtered.push(attrs);
      } else if (allDay) {
        allDayPrevious = false;
      }
    }

    return filtered;
  }, []).sort((a, b) => Boolean(b.allDay) - Boolean(a.allDay));
};

export { eventLabel, googleUri, icsUri, eventsForDay, isAllDay, setupEvent, timezoneLabel };
