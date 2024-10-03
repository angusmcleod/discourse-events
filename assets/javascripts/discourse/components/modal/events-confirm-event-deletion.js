import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import Event from "../../models/event";

const DELETE_TARGETS = ["events_only", "events_and_topics", "topics_only"];

export default Component.extend({
  deleteTargets: DELETE_TARGETS.map((t) => ({
    id: t,
    name: I18n.t(`admin.events.event.delete.${t}`),
  })),
  deleteTarget: "events_only",

  @discourseComputed("deleteTarget")
  btnLabel(deleteTarget) {
    return `admin.events.event.delete.${deleteTarget}_btn`;
  },

  actions: {
    delete() {
      const eventIds = this.model.eventIds;
      const target = this.deleteTarget;

      const opts = {
        event_ids: eventIds,
        target,
      };

      this.set("destroying", true);

      Event.destroy(opts)
        .then((result) => {
          if (result.success) {
            this.model.onDestroyEvents(
              eventIds.filter((eventId) =>
                result.destroyed_event_ids.includes(eventId)
              ),
              eventIds.filter((eventId) =>
                result.destroyed_topics_event_ids.includes(eventId)
              )
            );
            this.closeModal();
          } else {
            this.set("model.error", result.error);
          }
        })
        .finally(() => this.set("destroying", false));
    },

    cancel() {
      this.closeModal();
    },
  },
});
