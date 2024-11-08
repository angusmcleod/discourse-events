import { getOwner } from "@ember/application";
import Component from "@ember/component";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import User from "discourse/models/user";
import discourseComputed from "discourse-common/utils/decorators";
import I18n from "I18n";

export default Component.extend({
  userList: [],
  type: "going",
  title: I18n.t("event_rsvp.attendees.title"),

  didReceiveAttrs() {
    this._super();
    this.setUserList();
  },

  @action
  setUserList() {
    this.set("loadingList", true);

    const type = this.get("type");
    const topic = this.get("model.topic");

    ajax("/discourse-events/rsvp/users", {
      data: {
        type,
        topic_id: topic.id,
      },
    })
      .then((response) => {
        let userList = response.users || [];

        this.setProperties({
          userList,
          loadingList: false,
        });
      })
      .catch((e) => {
        this.set("flash", extractError(e));
      })
      .finally(() => {
        this.setProperties({
          loadingList: false,
        });
      });
  },

  @discourseComputed("type")
  goingNavClass(type) {
    return type === "going" ? "active" : "";
  },

  @discourseComputed("type")
  invitedNavClass(type) {
    return type === "invited" ? "active" : "";
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
