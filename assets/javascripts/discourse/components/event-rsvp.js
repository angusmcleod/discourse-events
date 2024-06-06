import { popupAjaxError } from "discourse/lib/ajax-error";
import { default as discourseComputed } from "discourse-common/utils/decorators";
import { ajax } from "discourse/lib/ajax";
import Component from "@ember/component";
import { equal, gt, notEmpty } from "@ember/object/computed";
import I18n from "I18n";
import { action } from "@ember/object";
import { service } from "@ember/service";
import EventRsvp from "./modal/event-rsvp";

export default Component.extend({
  classNames: "event-rsvp",
  goingSaving: false,
  modal: service(),

  didReceiveAttrs() {
    const currentUser = this.currentUser;
    const eventGoing = this.topic.event.going;

    this.setProperties({
      goingTotal: eventGoing ? eventGoing.length : 0,
      userGoing:
        currentUser &&
        eventGoing &&
        eventGoing.indexOf(currentUser.username) > -1,
    });
  },

  @discourseComputed("userGoing")
  goingClasses(userGoing) {
    return userGoing ? "btn-primary" : "";
  },

  @discourseComputed("currentUser", "eventFull")
  canGo(currentUser, eventFull) {
    return currentUser && !eventFull;
  },

  hasGuests: gt("goingTotal", 0),
  hasMax: notEmpty("topic.event.going_max"),

  @discourseComputed("goingTotal", "topic.event.going_max")
  spotsLeft(goingTotal, goingMax) {
    return Number(goingMax) - Number(goingTotal);
  },

  eventFull: equal("spotsLeft", 0),

  @discourseComputed("hasMax", "eventFull")
  goingMessage(hasMax, full) {
    if (hasMax) {
      if (full) {
        return I18n.t("event_rsvp.going.max_reached");
      } else {
        const spotsLeft = this.get("spotsLeft");

        if (spotsLeft === 1) {
          return I18n.t("event_rsvp.going.one_spot_left");
        } else {
          return I18n.t("event_rsvp.going.x_spots_left", { spotsLeft });
        }
      }
    }

    return false;
  },

  updateTopic(userName, _action, type) {
    let existing = this.get(`topic.event.${type}`);
    let list = existing ? existing : [];
    let userGoing = _action === "add";

    if (userGoing) {
      list.push(userName);
    } else {
      list.splice(list.indexOf(userName), 1);
    }

    let props = {
      userGoing,
      goingTotal: list.length,
    };
    props[`topic.event.${type}`] = list;
    this.setProperties(props);
  },

  save(user, _action, type) {
    this.set(`${type}Saving`, true);

    ajax(`/discourse-events/rsvp/${_action}`, {
      type: "POST",
      data: {
        topic_id: this.get("topic.id"),
        type,
        usernames: [user.username],
      },
    })
      .then((result) => {
        if (result.success) {
          this.updateTopic(user.username, _action, type);
        }
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.set(`${type}Saving`, false);
      });
  },

  @action
  openModal() {
    event?.preventDefault();
    this.modal.show(EventRsvp, {
      model: {
        topic: this.get("topic"),
      },
    });
  },

  actions: {
    going() {
      const currentUser = this.get("currentUser");
      const userGoing = this.get("userGoing");

      let _action = userGoing ? "remove" : "add";

      this.save(currentUser, _action, "going");
    },
  },
});
