import { computed } from "@ember/object";
import { reads } from "@ember/object/computed";
import SingleSelectHeaderComponent from "select-kit/components/select-kit/single-select-header";

export default SingleSelectHeaderComponent.extend({
  classNameBindings: [
    "combo-box-header",
    "events-subscription-selector-header",
    "selectedContent.disabled",
  ],
  caretUpIcon: reads("selectKit.options.caretUpIcon"),
  caretDownIcon: reads("selectKit.options.caretDownIcon"),
  caretIcon: computed(
    "selectKit.isExpanded",
    "caretUpIcon",
    "caretDownIcon",
    function () {
      return this.selectKit.isExpanded ? this.caretUpIcon : this.caretDownIcon;
    }
  ),
});
