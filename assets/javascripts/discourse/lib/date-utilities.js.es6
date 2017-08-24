function eventLabel(event, args = {}) {
  let label = '';

  if (args['includeIcon']) {
    label += "<i class='fa fa-calendar'></i>"
  }

  let startFormat = args.short ? 'M-D, h:mm' : 'MMMM Do, h:mm';
  let diffDay = moment(event['start']).date() !== moment(event['end']).date();
  let endFormat = diffDay ? startFormat : 'h:mm';

  let dateString = moment(event['start']).format(startFormat) + ' - '
                   + moment(event['end']).format(endFormat);

  label += `<span>${dateString}</span>`;

  return label;
}

export { eventLabel };
