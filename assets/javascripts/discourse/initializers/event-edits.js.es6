import Composer from 'discourse/models/composer';
import ComposerBody from 'discourse/components/composer-body';
import Topic from 'discourse/models/topic';
import TopicController from 'discourse/controllers/topic';
import { default as computed, observes, on } from 'ember-addons/ember-computed-decorators';
import NavItem from 'discourse/models/nav-item';
import EditCategorySettings from 'discourse/components/edit-category-settings';
import TopicListItem from 'discourse/components/topic-list-item';
import DiscourseURL from 'discourse/lib/url';

export default {
  name: 'events-edits',
  initialize(){
    Composer.serializeOnCreate('event');
    Composer.serializeToTopic('event', 'topic.event');

    Composer.reopen({
      @computed('subtype', 'category.events_enabled', 'topicFirstPost', 'topic.event')
      showEventControls(subtype, categoryEnabled, topicFirstPost, event) {
        return topicFirstPost && (subtype === 'event' || categoryEnabled || event);
      }
    });

    ComposerBody.reopen({
      @observes('composer.event')
      resizeWhenEventAdded: function() {
        this.resize();
      },

      //necessary because empty inline block elements take up space.
      @observes('composer.showEventControls')
      applyEventInlineClass() {
        Ember.run.scheduleOnce('afterRender', this, () => {
          $('.composer-controls-event').toggleClass('show-control', Boolean(this.get('composer.showEventControls')));
          this.resize();
        });
      }
    });

    Topic.reopen({
      @computed('subtype', 'category.events_enabled')
      showEventControls(subtype, categoryEnabled) {
        return subtype === 'event' || categoryEnabled;
      },

      @computed('last_read_post_number', 'highest_post_number')
      topicListItemClasses(lastRead, highest) {
        let classes = "date-time title raw-link event-link";
        if (lastRead === highest) {
          classes += ' visited';
        }
        return classes;
      }
    });

    // necessary because topic-title plugin outlet only recieves model
    TopicController.reopen({
      @observes('editingTopic')
      setEditingTopicOnModel() {
        this.set('model.editingTopic', this.get('editingTopic'));
      }
    });

    NavItem.reopenClass({
      buildList(category, args) {
        let items = this._super(category, args);

        if (category) {
          items = items.reject((item) => item.name === 'agenda');

          if (category.events_enabled) {
            items.push(Discourse.NavItem.fromText('agenda', args));
          }
        }

        return items;
      }
    });

    TopicListItem.reopen({
      @on('didInsertElement')
      setupEventLink() {
        Ember.run.scheduleOnce('afterRender', this, () => {
          this.$('.event-link').on('click', Ember.run.bind(this, this.handleEventLabelClick));
        });
      },

      @on('willDestroyElement')
      teardownEventLink() {
        this.$('.event-link').off('click', Ember.run.bind(this, this.handleEventLabelClick));
      },

      handleEventLabelClick(e) {
        e.preventDefault();
        const topic = this.get('topic');
        this.appEvents.trigger('header:update-topic', topic);
        DiscourseURL.routeTo(topic.get('lastReadUrl'));
      }
    });

    EditCategorySettings.reopen({
      @computed('category')
      availableViews(category) {
        let views = this._super(...arguments);

        if (category.get('events_enabled')) {
          views.push(
            {name: I18n.t('filters.agenda.title'), value: 'agenda'}
          );
        }

        return views;
      },
    });
  }
};
