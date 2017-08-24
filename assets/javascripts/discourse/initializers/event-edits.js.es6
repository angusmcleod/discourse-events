import Composer from 'discourse/models/composer';
import ComposerBody from 'discourse/components/composer-body';
import Topic from 'discourse/models/topic';
import TopicController from 'discourse/controllers/topic';
import { default as computed, observes } from 'ember-addons/ember-computed-decorators';
import NavItem from 'discourse/models/nav-item';
import EditCategorySettings from 'discourse/components/edit-category-settings';

export default {
  name: 'events-edits',
  initialize(){
    Composer.serializeOnCreate('event');

    Composer.reopen({
      @computed('currentType', 'category.events_enabled', 'topicFirstPost')
      showEventControls(type, categoryEnabled, topicFirstPost) {
        return topicFirstPost && (type === 'event' || categoryEnabled);
      }
    })

    ComposerBody.reopen({
      @observes('composer.event')
      resizeWhenEventAdded: function() {
        this.resize();
      }
    })

    Topic.reopen({
      @computed('subtype', 'category.events_enabled')
      showEventControls(subtype, categoryEnabled) {
        return subtype === 'event' || categoryEnabled;
      },

      @computed('last_read_post_number', 'highest_post_number')
      topicListItemClasses(lastRead, highest) {
        let classes = "date-time title raw-link raw-topic-link";
        if (lastRead === this.get('highest_post_number')) {
          classes += ' visited';
        }
        return classes;
      }
    })

    // necessary because topic-title plugin outlet only recieves model
    TopicController.reopen({
      @observes('editingTopic')
      setEditingTopicOnModel() {
        this.set('model.editingTopic', this.get('editingTopic'));
      }
    })

    NavItem.reopenClass({
      buildList(category, args) {
        let items = this._super(category, args);

        if (category && category.events_enabled) {
          items.push(Discourse.NavItem.fromText('agenda', args));
        }

        return items;
      }
    })

    EditCategorySettings.reopen({
      @computed('category')
      availableViews(category) {
        let views = [
          {name: I18n.t('filters.latest.title'), value: 'latest'},
          {name: I18n.t('filters.top.title'),    value: 'top'},
        ]

        if (category.get('events_enabled')) {
          views.push(
            {name: I18n.t('filters.agenda.title'), value: 'agenda'}
          )
        }

        return views;
      },
    })
  }
}
