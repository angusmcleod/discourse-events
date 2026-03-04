import { service } from "@ember/service";
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

  @discourseComputed(
    "feature",
    "attribute",
    "subscription.features",
    "allowedValues"
  )
  content(feature, attribute, subscriptionFeatures, allowedValues) {
    const attributes = (subscriptionFeatures || {})[feature];
    if (!attributes) {
      return [];
    }

    const values = attributes[attribute];
    if (!values) {
      return [];
    } else {
      return Object.keys(values)
        .filter((value) =>
          allowedValues ? allowedValues.includes(value) : true
        )
        .map((value) => {
          let i18nkey = `admin.events.${feature}.${attribute}.${value}`;
          if (this.i18nSuffix) {
            i18nkey += `.${this.i18nSuffix}`;
          }
          return {
            id: value,
            name: I18n.t(i18nkey),
          };
        });
    }
  },

  modifyComponentForRow() {
    return "events-subscription-selector/events-subscription-selector-row";
  },
});
