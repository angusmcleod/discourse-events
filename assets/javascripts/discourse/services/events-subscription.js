import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const SUBSCRIBE_PATH = "/s";
const SUPPORT_PATH = "/";
const BASE_URL = "https://support.angus.blog";

export default class EventsSubscriptionService extends Service {
  @tracked subscribed = false;
  @tracked authorized = false;
  @tracked supplierId = null;
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

    this.authorized = result.authorized;
    this.supplierId = result.supplier_id;
    this.subscribed = result.subscribed;
    this.product = result.product;
    this.features = result.features;
  }

  supportsFeatureValue(feature, attribute, value) {
    if (!this.subscribed || !value || !attribute) {
      return false;
    } else {
      const featureValues = this.features[feature][attribute][value];
      return featureValues && featureValues[this.product];
    }
  }

  get upgradePath() {
    return BASE_URL + SUBSCRIBE_PATH;
  }

  get ctaPath() {
    switch (this.product) {
      case "none":
        return BASE_URL + SUBSCRIBE_PATH;
      case "community":
        return BASE_URL + SUPPORT_PATH;
      case "business":
        return BASE_URL + SUPPORT_PATH;
      default:
        return BASE_URL + SUBSCRIBE_PATH;
    }
  }
}
