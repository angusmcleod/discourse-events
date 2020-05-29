import { popupAjaxError } from 'discourse/lib/ajax-error';
import { default as discourseComputed } from 'discourse-common/utils/decorators';
import showModal from 'discourse/lib/show-modal';
import { ajax } from 'discourse/lib/ajax';
import Component from "@ember/component";
import { gt, notEmpty, equal } from "@ember/object/computed";
import I18n from "I18n";

export default Component.extend({
  classNames: 'event-rsvp',
  goingSaving: false,

  @discourseComputed('currentUser', 'topic.event.going')
  userGoing(user, eventGoing) {
    return eventGoing && eventGoing.indexOf(user.username) > -1;
  },

  @discourseComputed('topic.event.going')
  goingTotal(eventGoing) {
    if (eventGoing) {
      return eventGoing.length;
    } else {
      return 0;
    }
  },

  @discourseComputed('userGoing')
  goingClasses(userGoing) {
    return userGoing ? 'btn-primary' : '';
  },

  @discourseComputed('currentUser', 'eventFull')
  canGo(currentUser, eventFull) {
    return currentUser && !eventFull;
  },

  hasGuests: gt('goingTotal', 0),
  hasMax: notEmpty('topic.event.going_max'),

  @discourseComputed('goingTotal', 'topic.event.going_max')
  spotsLeft(goingTotal, goingMax) {
    return Number(goingMax) - Number(goingTotal);
  },

  eventFull: equal('spotsLeft', 0),

  @discourseComputed('hasMax', 'eventFull')
  goingMessage(hasMax, full) {
    if (hasMax) {
      if (full) {
        return I18n.t('event_rsvp.going.max_reached');
      } else {
        const spotsLeft = this.get('spotsLeft');

        if (spotsLeft === 1) {
          return I18n.t('event_rsvp.going.one_spot_left');
        } else {
          return I18n.t('event_rsvp.going.x_spots_left', { spotsLeft });
        }
      }
    }

    return false;
  },

  updateTopic(userName, action, type) {
    let existing = this.get(`topic.event.${type}`);
    let list = existing ? existing : [];

    if (action === 'add') {
      list.push(userName);
    } else {
      list.splice(list.indexOf(userName), 1);
    }

    this.set(`topic.event.${type}`, list);
    this.notifyPropertyChange(`topic.event.${type}`);
  },

  save(user, action, type) {
    this.set(`${type}Saving`, true);

    ajax(`/calendar-events/rsvp/${action}`, {
      type: 'POST',
      data: {
        topic_id: this.get('topic.id'),
        type,
        usernames: [user.username]
      }
    }).then((result) => {
      if (result.success) {
        this.updateTopic(user.username, action, type);
      }
    }).catch(popupAjaxError).finally(() => {
      this.set(`${type}Saving`, false);
    });
  },

  actions: {
    going() {
      const currentUser = this.get('currentUser');
      const userGoing = this.get('userGoing');

      let action = userGoing ? 'remove' : 'add';

      this.save(currentUser, action, 'going');
    },

    openModal() {
      const topic = this.get('topic');
      const controller = showModal('event-rsvp', {
        model: {
          topic
        }
      });
    }
  }
})
