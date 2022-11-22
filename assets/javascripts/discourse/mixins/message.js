import EmberObject from "@ember/object";
import Mixin from "@ember/object/mixin";

const defaultMessage = EmberObject.create({
  key: "info",
});

export default Mixin.create({
  message: defaultMessage,

  setMessage(key, type, opts) {
    this.get("message").setProperties({ key, type, opts });
  },

  actions: {
    setMessage(key, type = "info", opts = {}) {
      this.setMessage(key, type, opts);
    },
  },
});
