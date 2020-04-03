import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import { getOwner } from 'discourse-common/lib/get-owner';
import { ajax } from 'discourse/lib/ajax';
import ModalFunctionality from "discourse/mixins/modal-functionality";
import { extractError } from 'discourse/lib/ajax-error';

export default Ember.Controller.extend(ModalFunctionality, {
  filter: null,
  userList: [],
  type: 'going',

  @observes('type', 'model.topic')
  setUserList() {
    this.set('loadingList', true);

    const type = this.get('type');
    const topic = this.get('model.topic');

    let usernames = topic.get(`event.${type}`);

    if (!usernames || !usernames.length) return;

    let userList = [];

    ajax('/calendar-events/rsvp/users', {
      data:{
        usernames
      }
    }).then((response) => {
      let userList = response.users || [];
      
      this.setProperties({
        userList,
        loadingList: false
      });
    }).catch(e => {
      this.flash(extractError(e),'alert-error');
    })
    .finally(()=>{
      this.setProperties({
        loadingList: false
      });
    })
  },

  @discourseComputed('type')
  goingNavClass(type) {
    return type === 'going' ? 'active' : '';
  },

  @discourseComputed('userList', 'filter')
  filteredList(userList, filter) {
    if (filter) {
      userList = userList.filter((u) => u.username.indexOf(filter) > -1);
    }

    const currentUser = this.get('currentUser');
    if (currentUser) {
      userList.sort((a, b) => {
        if (a.username === currentUser.username) {
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
