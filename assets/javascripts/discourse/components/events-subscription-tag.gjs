import Component from "@glimmer/component";
import { dasherize } from "@ember/string";
import I18n from "I18n";

export default class EventsSubscriptionTag extends Component {
  get title() {
    return I18n.t(
      `admin.events.subscription.tags.${this.args.subscription}.title`
    );
  }

  get class() {
    return `events-subscription-tag ${dasherize(this.args.subscription)}`;
  }

  get label() {
    return I18n.t(
      `admin.events.subscription.tags.${this.args.subscription}.label`
    );
  }

  <template>
    <span class={{this.class}} title={{this.title}}>
      {{this.label}}
    </span>
  </template>
}
