let eventLabel = function(event, args = {}) {
  const icon = Discourse.SiteSettings.events_event_label_icon;
  const format = Discourse.SiteSettings.events_event_label_format;
  const shortFormat = Discourse.SiteSettings.events_event_label_short_format;
  const shortOnlyStart = Discourse.SiteSettings.events_event_label_short_only_start;

  let label = `<i class='fa fa-${icon}'></i>`;

  if (!args.mobile) {
    const startFormat = args.short ? shortFormat : format;

    let dateString =  moment(event['start']).format(startFormat);

    if (!args.short || !shortOnlyStart) {
      const diffDay = moment(event['start']).date() !== moment(event['end']).date();
      const formatArr = startFormat.split(',');
      const endFormat = diffDay ? startFormat : formatArr[formatArr.length - 1];
      const end = moment(event['end']).format(endFormat);

      dateString += `– ${end}`;
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

export { eventLabel, googleUri, icsUri };
