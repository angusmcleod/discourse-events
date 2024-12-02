import EmberObject, { action } from "@ember/object";
import Mixin from "@ember/object/mixin";

const defaultMessage = EmberObject.create({
  key: "info",
});

export default Mixin.create({
  message: defaultMessage,

  @action
  setMessage(key, type = "info", opts = {}) {
    this.get("message").setProperties({ key, type, opts });
  },
});
