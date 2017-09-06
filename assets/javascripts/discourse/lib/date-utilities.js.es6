function eventLabel(event, args = {}) {
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

export { eventLabel };
