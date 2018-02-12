let eventLabel = function(event, args = {}) {
  const icon = Discourse.SiteSettings.events_event_label_icon;
  const longFormat = Discourse.SiteSettings.events_event_label_format;
  const shortFormat = Discourse.SiteSettings.events_event_label_short_format;
  const shortOnlyStart = Discourse.SiteSettings.events_event_label_short_only_start;
  const includeTimeZone = Discourse.SiteSettings.events_event_label_include_timezone;

  let label = `<i class='fa fa-${icon}'></i>`;

  if (!args.mobile) {
    let start = moment(event['start']);
    let end = moment(event['end']);
    let allDay = false;

    if (event['start'] && event['end']) {
      const startIsDayStart = start.hour() === 0 && start.minute() === 0;
      const endIsDayEnd = end.hour() === 23 && end.minute() === 59;
      allDay = startIsDayStart && endIsDayEnd;
    }

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

    if (includeTimeZone) {
      dateString += `, ${start.format('Z')}`;
    }

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

let eventsForDate = function(date, topics, args = {}) {
  return topics.reduce((filtered, t) => {
    const start = moment(t.event.start);
    const end = moment(t.event.end);
    let attrs = {
      topicId: t.id
    };

    if (date.isSame(start, "day")) {
      const startIsDayStart = start.hour() === 0 && start.minute() === 0;
      const endIsDayEnd = end.hour() === 23 && end.minute() === 59;

      if ((startIsDayStart && endIsDayEnd)) {
        attrs['classes'] = 'all-day';
      } else {
        attrs['time'] = moment(t.event.start).format('h:mm a');
        if (t.event.end && !date.isSame(end, "day")) {
          attrs['classes'] = 'all-day';
        }
      }
      attrs['title'] = t.title;
      filtered.push(attrs);
    } else if (t.event.end && date.isSame(end, "day") || date.isBetween(t.event.start, t.event.end, "day")) {
      attrs['classes'] = 'all-day';

      if (args.dateEvents || (args.start && date.isSame(args.start, "day")))   {
        attrs['title'] = t.title;
      }

      filtered.push(attrs);
    }

    return filtered;
  }, []);
};

export { eventLabel, googleUri, icsUri, eventsForDate };
