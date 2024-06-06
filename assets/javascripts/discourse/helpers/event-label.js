import { htmlSafe } from "@ember/template";
import { helperContext, registerRawHelper } from "discourse-common/lib/helpers";
import { eventLabel } from "../lib/date-utilities";

registerRawHelper("event-label", eventLabelHelper);

export default function eventLabelHelper(event, args) {
  let siteSettings = helperContext().siteSettings;
  return htmlSafe(eventLabel(event, Object.assign({}, args, { siteSettings })));
}
