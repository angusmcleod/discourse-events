import { default as computed, observes, on } from 'ember-addons/ember-computed-decorators';
import { getOwner } from 'discourse-common/lib/get-owner';
import User from 'discourse/models/user';

export default Ember.Controller.extend({
  filter: null,
  userList: [],
  type: 'going',

  @observes('type', 'model.topic')
  setUserList() {
    this.set('loadingList', true);

    const type = this.get('type');
    const topic = this.get('model.topic');

    let usernames = topic.get(`event_${type}`);

    if (!usernames || !usernames.length) return;

    let userList = [];

    usernames.forEach((username, index) => {
      User.findByUsername(username).then((user) => {
        userList.push(user);

        if (userList.length == usernames.length) {
          this.setProperties({
            userList,
            loadingList: false
          })
        }
      })
    });
  },

  @computed('type')
  goingNavClass(type) {
    return type === 'going' ? 'active' : '';
  },

  @computed('userList', 'filter')
  filteredList(userList, filter) {
    if (filter) {
      userList = userList.filter((u) => u.username.indexOf(filter) > -1);
    }

    const currentUser = this.get('currentUser');
    if (currentUser) {
      userList.sort((a, b) => {
        if (a.id === currentUser.id) {
          return -1;
        } else {
          return 1;
        }
      });
    }

    return userList;
  },

  actions: {
    setType(type) {
      this.set('type', type);
    },

    composePrivateMessage(user) {
      const controller = getOwner(this).lookup('controller:application');
      this.send('closeModal');
      controller.send('composePrivateMessage', user);
    }
  }
});
