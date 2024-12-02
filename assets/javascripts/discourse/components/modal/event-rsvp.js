import { getOwner } from "@ember/application";
import Component from "@ember/component";
import { action } from "@ember/object";
import User from "discourse/models/user";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";
import EventRsvp, { rsvpTypes } from "../../models/event-rsvp";

export default Component.extend({
  userList: [],
  type: "going",
  title: I18n.t("event_rsvp.attendees.title"),
  rsvpTypes,

  didReceiveAttrs() {
    this._super();
    this.setUserList();
  },

  @action
  setUserList() {
    this.set("loadingList", true);

    const type = this.get("type");
    const topic = this.get("model.topic");
    const data = {
      type,
      topic_id: topic.id,
    };
    EventRsvp.list(data).then((response) => {
      let userList = response.users || [];

      this.setProperties({
        userList,
        loadingList: false,
      });
    });
  },

  @action
  navClass(type) {
    return type === this.get("type") ? "active" : "";
  },

  @discourseComputed("userList")
  filteredList(userList) {
    const currentUser = this.get("currentUser");
    if (currentUser) {
      userList.sort((a) => {
        if (a.username === currentUser.username) {
          return -1;
        } else {
          return 1;
        }
      });
    }
    return userList;
  },

  @action
  setType(type) {
    event?.preventDefault();
    this.set("type", type);
    this.setUserList();
  },

  @action
  composePrivateMessage(user) {
    const controller = getOwner(this).lookup("controller:application");
    this.closeModal();
    controller.send("composePrivateMessage", User.create(user));
  },
});
