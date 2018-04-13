import { registerUnbound } from 'discourse-common/lib/helpers';
import { eventLabel } from '../lib/date-utilities';

export default registerUnbound('event-label', function(event, args) {
  return new Handlebars.SafeString(eventLabel(event, args));
});
