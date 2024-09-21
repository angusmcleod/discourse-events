import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import DButton from "discourse/components/d-button";
import DiscourseURL from "discourse/lib/url";
import I18n from "I18n";

export default class EventsSubscriptionBadge extends Component {
  @service("events-subscription") subscription;
  @tracked updating = false;
  @tracked updateIcon = "sync";

  get i18nKey() {
    return `admin.events.subscription.type.${
      this.subscription.product || "none"
    }`;
  }

  get title() {
    return I18n.t(`${this.i18nKey}.title`);
  }

  get label() {
    return I18n.t(`${this.i18nKey}.label`);
  }

  get classes() {
    let classes = "btn-primary events-subscription-badge";
    if (this.subscription.product) {
      classes += ` ${this.subscription.product}`;
    }
    return classes;
  }

  @action
  click() {
    DiscourseURL.routeTo(this.subscription.ctaPath);
  }

  @action
  update() {
    this.updating = true;
    this.updateIcon = null;
    this.subscription.getSubscriptionStatus(true).finally(() => {
      this.updateIcon = "sync";
      this.updating = false;
    });
  }

  <template>
    <DButton
      @icon={{this.updateIcon}}
      @action={{this.update}}
      class="btn update-subscription-status"
      @disabled={{this.updating}}
      @title="admin.events.subscription.update.title"
    >
      <ConditionalLoadingSpinner @condition={{this.updating}} @size="small" />
    </DButton>
    <DButton
      @action={{this.click}}
      class={{this.classes}}
      @translatedTitle={{this.title}}
      @translatedLabel={{this.label}}
    />
  </template>
}
