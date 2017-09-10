let eventLabel = function(event, args = {}) {
  let label = '';

  if (args['includeIcon']) {
    label += "<i class='fa fa-calendar'></i>"
  }

  let startFormat = args.short ? 'M-D, HH:mm' : 'MMMM Do, HH:mm';
  let diffDay = moment(event['start']).date() !== moment(event['end']).date();
  let endFormat = diffDay ? startFormat : 'HH:mm';

  let dateString = moment(event['start']).format(startFormat) + ' - '
                   + moment(event['end']).format(endFormat);

  label += `<span>${dateString}</span>`;

  return label;
}

let utcDateTime = function(dateTime) {
  return moment.parseZone(dateTime).utc().format().replace(/-|:|\.\d\d\d/g,"");
};

let googleUri = function(params) {
  let href = "https://www.google.com/calendar/render?action=TEMPLATE";

  if (params.title) {
    href += `&text=${params.title.replace(/ /g,'+').replace(/[^\w+]+/g,'')}`;
  }

  href += `&dates=${utcDateTime(params.event.start)}/${utcDateTime(params.event.end)}`;

  href += `&details=${params.details || I18n.t('add_to_calendar.default_details')}`;

  if (params.location) {
    href += `&location=${params.location}`;
  }

  href += "&sf=true&output=xml";

  return href;
}

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
}

export { eventLabel, googleUri, icsUri };
