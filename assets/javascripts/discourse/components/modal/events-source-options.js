import Component from "@ember/component";
import { action } from "@ember/object";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend({
  @discourseComputed("model.providerType")
  title(providerType) {
    const providerLabel = I18n.t(
      `admin.events.provider.provider_type.${providerType}`
    );
    const optsLabel = I18n.t("admin.events.source.source_options.label");
    return `${providerLabel} ${optsLabel}`;
  },

  @discourseComputed("model.source.source_options.@each")
  sourceOptions(source_options) {
    return this.model.sourceOptionFields.map((opt) => {
      return {
        name: opt.name,
        value: source_options[opt.name],
        type: opt.type,
      };
    });
  },

  @action
  updateSourceOptions(name, event) {
    this.model.source.source_options.set(name, event.target.value);
  },
});
