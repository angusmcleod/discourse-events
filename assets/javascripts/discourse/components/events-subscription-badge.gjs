import { inject as service } from "@ember/service";
import { action, computed } from "@ember/object";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import DiscourseURL from "discourse/lib/url";
import DButton from "discourse/components/d-button";
import ConditionalLoadingSpinner from "discourse/components/conditional-loading-spinner";
import I18n from "I18n";

export default class WizardSubscriptionBadge extends Component {
  @service subscription;
  @tracked updating = false;
  @tracked updateIcon = "sync";

  get i18nKey() {
    return `admin.events.subscription.type.${this.subscription.product || "none"}`;
  }

  get title() {
    return `${this.i18nKey}.title`;
  }

  get label() {
    return I18n.t(`${this.i18nKey}.label`);
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
      class="btn update"
      @disabled={{this.updating}}
      @title="admin.events.subscription.update.title"
    >
      <ConditionalLoadingSpinner @condition={{this.updating}} @size="small" />
    </DButton>
    <DButton
      @action={{this.click}}
      class="events-subscription-badge {{this.subscription.subscriptionType}}"
      @translatedTitle={{this.title}}
      @translatedLabel={{this.label}}
    />
  </template>
}
