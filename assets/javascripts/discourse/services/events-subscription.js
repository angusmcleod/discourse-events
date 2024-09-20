import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const SUBSCRIBE_PATH = "/subscribe";
const SUPPORT_PATH = "/new-message?username=angus&title=Events%20Support";

export default class EventsSubscriptionService extends Service {
  @tracked subscribed = false;
  @tracked product = "";
  @tracked features = {};

  async init() {
    super.init(...arguments);
    await this.getSubscriptionStatus();
  }

  async getSubscriptionStatus(update = false) {
    let url = "/admin/plugins/events/subscription";
    if (update) {
      url += "?update_from_remote=true";
    }
    let result = await ajax(url).catch(popupAjaxError);

    this.subscribed = result.subscribed;
    this.product = result.product;
    this.features = result.features;
  }

  supportsFeatureValue(feature, value) {
    if (!this.subscribed || !value) {
      return false;
    } else {
      return this.features[feature][value][this.product];
    }
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
