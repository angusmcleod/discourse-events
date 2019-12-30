import { popupAjaxError } from 'discourse/lib/ajax-error';
import { default as computed } from 'ember-addons/ember-computed-decorators';
import showModal from 'discourse/lib/show-modal';
import { ajax } from 'discourse/lib/ajax';

export default Ember.Component.extend({
  classNames: 'event-rsvp',
  goingSaving: false,

  @computed('currentUser', 'topic.event_going')
  userGoing(user, eventGoing) {
    return eventGoing && eventGoing.indexOf(user.username) > -1;
  },

  @computed('topic.event_going')
  goingTotal(eventGoing) {
    if (eventGoing) {
      return eventGoing.length;
    } else {
      return 0;
    }
  },

  @computed('userGoing')
  goingClasses(userGoing) {
    return userGoing ? 'btn-primary' : '';
  },

  @computed('currentUser', 'eventFull')
  canGo(currentUser, eventFull) {
    return currentUser && !eventFull;
  },

  hasGuests: Ember.computed.gt('goingTotal', 0),

  hasMax: Ember.computed.notEmpty('topic.event.going_max'),

  @computed('goingTotal', 'topic.event.going_max')
  spotsLeft(goingTotal, goingMax) {
    return Number(goingMax) - Number(goingTotal);
  },

  eventFull: Ember.computed.equal('spotsLeft', 0),

  @computed('hasMax', 'eventFull')
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
    let existing = this.get(`topic.event_${type}`);
    let list = existing ? existing : [];

    if (action === 'add') {
      list.push(userName);
    } else {
      list.splice(list.indexOf(userName), 1);
    }

    this.set(`topic.event_${type}`, list);
    this.notifyPropertyChange(`topic.event_${type}`);
  },

  save(user, action, type) {
    this.set(`${type}Saving`, true);

    ajax(`/calendar-events/rsvp/${action}`, {
      type: 'POST',
      data: {
        topic_id: this.get('topic.id'),
        type,
        user_name: user.username
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
