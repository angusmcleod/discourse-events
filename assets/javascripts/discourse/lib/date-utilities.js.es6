let eventLabel = function(event, args = {}) {
  const icon = Discourse.SiteSettings.events_event_label_icon;
  const format = Discourse.SiteSettings.events_event_label_format;
  const shortFormat = Discourse.SiteSettings.events_event_label_short_format;

  let label = `<i class='fa fa-${icon}'></i>`;

  if (!args.mobile) {
    let startFormat = args.short ? shortFormat : format;
    let diffDay = moment(event['start']).date() !== moment(event['end']).date();

    // end datetime format: if the event is shorter than a day just show the end time.
    let formatArr = startFormat.split(',');
    let endFormat = diffDay ? startFormat : formatArr[formatArr.length - 1];

    let dateString = moment(event['start']).format(startFormat) + ' - '
                     + moment(event['end']).format(endFormat);

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
