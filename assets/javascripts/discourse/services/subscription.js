import Service from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const SUBSCRIBE_PATH = "/subscribe";
const SUPPORT_PATH = "/new-message?username=angus&title=Events%20Support";

export default class SubscriptionService extends Service {
  @tracked subscribed = false;
  @tracked subscriptionProduct = "";
  @tracked businessSubscription = false;
  @tracked communitySubscription = false;
  @tracked standardSubscription = false;

  async getSubscriptionStatus(update = false) {
    let url = "/admin/plugins/events/subscription";
    if (update) {
      url += "?update_from_remote=true";
    }
    let result = await ajax(url).catch(popupAjaxError);

    this.subscribed = result.subscribed;
    this.subscriptionProduct = result.product;
    this.businessSubscription = this.subscriptionType === "business";
    this.communitySubscription = this.subscriptionType === "community";
    this.standardSubscription = this.subscriptionType === "standard";
  }

  get ctaPath() {
    switch (this.product) {
      case "none":
        return SUBSCRIBE_PATH;
      case "community":
        return SUPPORT_PATH;
      case "business":
        return SUPPORT_PATH;
      default:
        return SUBSCRIBE_PATH;
    }
  }
}
