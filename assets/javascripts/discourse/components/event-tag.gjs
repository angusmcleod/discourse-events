import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import DiscourseURL from "discourse/lib/url";

export default class EventTag extends Component {
  get class() {
    return `event-tag ${this.args.class}`;
  }

  @action
  click() {
    event?.preventDefault();
    event?.stopPropagation();

    if (this.args.href) {
      DiscourseURL.routeTo(this.args.href);
    }
  }

  <template>
    <a class={{this.class}} {{on "click" this.click}} role="button">
      <span>{{@label}}</span>
    </a>
  </template>
}
