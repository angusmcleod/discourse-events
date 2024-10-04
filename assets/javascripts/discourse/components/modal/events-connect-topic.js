import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import Event from "../../models/event";

export default Component.extend({
  createTopic: false,

  @discourseComputed("connecting", "topicId", "createTopic", "client")
  connectDisabled(connecting, topicId, createTopic, client) {
    return connecting || (!topicId && !createTopic) || !client;
  },

  actions: {
    connect() {
      if (this.connectDisabled) {
        return;
      }

      const opts = {
        event_id: this.model.event.id,
        client: this.client,
      };

      if (this.topicId) {
        opts.topic_id = this.topicId;
      }

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
