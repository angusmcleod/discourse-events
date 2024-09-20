import { inject as service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import SingleSelectComponent from "select-kit/components/single-select";

export default SingleSelectComponent.extend({
  classNames: ["combo-box", "events-subscription-selector"],
  subscription: service("events-subscription"),

  selectKitOptions: {
    autoFilterable: false,
    filterable: false,
    showFullTitle: true,
    headerComponent:
      "events-subscription-selector/events-subscription-selector-header",
    caretUpIcon: "caret-up",
    caretDownIcon: "caret-down",
  },

  @discourseComputed("feature", "subscription.features")
  content(feature, subscriptionFeatures) {
    const values = (subscriptionFeatures || {})[feature];

    if (!values) {
      return [];
    } else {
      return Object.keys(values).map((value) => {
        let minimumProduct = Object.keys(values[value]).find(
          (product) => values[value][product]
        );
        let subscriptionRequired = minimumProduct !== "none";

        let attrs = {
          id: value,
          name: I18n.t(`admin.events.${feature}.${this.i18nKey}.${value}`),
          subscriptionRequired,
          minimumProduct,
        };

        if (subscriptionRequired) {
          attrs.subscribed = this.subscription.supportsFeatureValue(
            feature,
            value
          );
          attrs.disabled = !attrs.subscribed;
          attrs.selectorLabel = `admin.events.subscription.${
            attrs.subscribed ? "subscribed" : "not_subscribed"
          }.selector`;
        }

        return attrs;
      });
    }
  },

  modifyComponentForRow() {
    return "events-subscription-selector/events-subscription-selector-row";
  },
});
