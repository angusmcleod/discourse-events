import { helperContext, registerUnbound } from "discourse-common/lib/helpers";
import { htmlSafe } from "@ember/template";
import { eventLabel } from '../lib/date-utilities';

export default registerUnbound('event-label', function(event, args) {
  let siteSettings = helperContext().siteSettings;
  return htmlSafe(eventLabel(event, Object.assign({}, args, { siteSettings })));
});
