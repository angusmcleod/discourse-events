import {
  default as discourseComputed,
  observes,
} from "discourse-common/utils/decorators";
import { getOwner } from "@ember/application";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import Component from "@ember/component";
import { action } from "@ember/object";
import User from "discourse/models/user";

export default Component.extend({
  userList: [],
  type: "going",
  title: I18n.t('event_rsvp.modal.title'),

  didReceiveAttrs() {
    this.setUserList();
  },

  @observes("type", "model.topic")
  setUserList() {
    this.set("loadingList", true);

    const type = this.get("type");
    const topic = this.get("model.topic");

    let usernames = topic.get(`event.${type}`);

    if (!usernames || !usernames.length) {
      return;
    }

    ajax("/discourse-events/rsvp/users", {
      data: {
        usernames,
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
  },

  @action
  composePrivateMessage(user) {
    const controller = getOwner(this).lookup("controller:application");
    this.closeModal();
    controller.send("composePrivateMessage", User.create(user));
  },
});
