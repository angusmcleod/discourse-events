import { later } from "@ember/runloop";
import $ from "jquery";
import copyText from "discourse/lib/copy-text";
import DropdownSelectBoxRowComponent from "select-kit/components/dropdown-select-box/dropdown-select-box-row";

export default DropdownSelectBoxRowComponent.extend({
  layoutName: "discourse/templates/components/events-calendar-subscription-row",
  classNames: "events-calendar-subscription-row",

  click() {
    const $copyRange = $('<p id="copy-range"></p>');
    $copyRange.html(this.item.id);

    $(document.body).append($copyRange);

    if (copyText(this.item.id, $copyRange[0])) {
      this.set("copiedUrl", true);
      later(() => this.set("copiedUrl", false), 2000);
    }

    $copyRange.remove();
  },
});
