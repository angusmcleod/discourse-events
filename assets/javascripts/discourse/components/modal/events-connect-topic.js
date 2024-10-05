import Component from "@ember/component";
import { service } from "@ember/service";
import discourseComputed from "discourse-common/utils/decorators";
import Event from "../../models/event";

export default Component.extend({
  createTopic: false,
  siteSettings: service(),

  @discourseComputed("connecting", "topicId", "createTopic", "client")
  connectDisabled(connecting, topicId, createTopic, client) {
    return connecting || (!topicId && !createTopic) || !client;
  },

  @discourseComputed(
    "siteSettings.calendar_enabled",
    "siteSettings.discourse_post_event_enabled"
  )
  allowedClientValues(calendarEnabled, postEventEnabled) {
    let allowedClients = ["discourse_events"];
    if (calendarEnabled && postEventEnabled) {
      allowedClients.push("discourse_calendar");
    }
    return allowedClients;
  },

  actions: {
    connectTopic() {
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

      if (this.createTopic) {
        opts.category_id = this.category_id;
        opts.username = this.username;
      }

      this.set("connecting", true);

      Event.connectTopic(opts)
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
