import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { not } from "@ember/object/computed";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class EventsSubscriptionStatus extends Component {
  @service siteSettings;
  @service("events-subscription") subscription;
  @tracked unauthorizing = false;
  @not("subscription.supplierId") authorizeDisabled;
  basePath = "/admin/plugins/subscription-client/suppliers";

  @action
  authorize() {
    window.location.href = `${this.basePath}/authorize?supplier_id=${this.subscription.supplierId}&final_landing_path=/admin/plugins/events`;
  }

  @action
  deauthorize() {
    this.unauthorizing = true;

    ajax(`${this.basePath}/authorize`, {
      type: "DELETE",
      data: {
        supplier_id: this.subscription.supplierId,
      },
    })
      .then((result) => {
        if (result.success) {
          this.subscription.supplierId = result.supplier_id;
          this.subscription.authorized = false;
        }
      })
      .finally(() => {
        this.unauthorizing = false;
      })
      .catch(popupAjaxError);
  }
}
