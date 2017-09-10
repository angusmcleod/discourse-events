import { registerUnbound } from 'discourse-common/lib/helpers';
import { googleCalendarLink } from '../lib/date-utilities';

export default registerUnbound('google-calendar-link', function(event, opts) {
  return new Handlebars.SafeString(googleCalendarLink(event, opts));
});
