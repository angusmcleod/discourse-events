import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not } from "@ember/object/computed";

const supplierUrl = "https://support.angus.blog"

export default class EventsSubscriptionStatus extends Component {
  @service siteSettings;
  @tracked supplierId = null;
  @tracked authorized = false;
  @tracked unauthorizing = false;
  @not("supplierId") authorizeDisabled;
  basePath = "/admin/plugins/subscription-client/suppliers";

  constructor() {
    super(...arguments);
    ajax(`${this.basePath}`).then((result) => {
      const supplier = result.suppliers.find((s) => s.url === supplierUrl);
      if (supplier) {
        this.supplierId = supplier.id;
        this.authorized = supplier.authorized;
      }
    });
  }

  @action
  authorize() {
    window.location.href = `${this.basePath}/authorize?supplier_id=${this.supplierId}&final_landing_path=/admin/plugins/events`;
  }

  @action
  deauthorize() {
    this.unauthorizing = true;

    ajax(`${this.basePath}/authorize`, {
      type: "DELETE",
      data: {
        supplier_id: this.supplierId,
      },
    })
      .then((result) => {
        if (result.success) {
          this.supplierId = result.supplier_id;
          this.authorized = false;
        }
      })
      .finally(() => {
        this.unauthorizing = false;
      })
      .catch(popupAjaxError);
  }
}
