import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import Event from "../../models/event";

export default Component.extend({
  @discourseComputed("connecting", "topicId", "client")
  connectDisabled(connecting, topicId, client) {
    return connecting || !topicId || !client;
  },

  actions: {
    connect() {
      if (this.connectDisabled) {
        return;
      }

      const opts = {
        event_id: this.model.event.id,
        topic_id: this.topicId,
        client: this.client,
      };

      this.set("connecting", true);

      Event.connect(opts)
        .then((result) => {
          if (result.success) {
            this.model.onConnectTopic();
            this.closeModal();
          } else {
            this.set("model.error", result.error);
          }
        })
        .finally(() => this.set("connecting", false));
    },

    cancel() {
      this.closeModal();
    },
  },
});
