import { tracked } from "@glimmer/tracking";
import Service from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class EventsSubscriptionService extends Service {
  @tracked product = "enterprise";
  @tracked features = {};

  async init() {
    super.init(...arguments);
    await this.getSubscriptionStatus();
  }

  async getSubscriptionStatus() {
    let result = await ajax("/admin/plugins/events/subscription").catch(
      popupAjaxError
    );

    this.product = result.product;
    this.features = result.features;
  }
}
