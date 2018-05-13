import Composer from 'discourse/models/composer';
import ComposerBody from 'discourse/components/composer-body';
import Topic from 'discourse/models/topic';
import TopicController from 'discourse/controllers/topic';
import { default as computed, observes, on } from 'ember-addons/ember-computed-decorators';
import NavItem from 'discourse/models/nav-item';
import EditCategorySettings from 'discourse/components/edit-category-settings';
import TopicListItem from 'discourse/components/topic-list-item';
import DiscourseURL from 'discourse/lib/url';
import { withPluginApi } from 'discourse/lib/plugin-api';
import { calendarRange } from '../lib/date-utilities';

export default {
  name: 'events-edits',
  initialize(container) {
    const siteSettings = container.lookup('site-settings:main');

    Composer.serializeOnCreate('event');
    Composer.serializeToTopic('event', 'topic.event');

    Composer.reopen({
      @computed('subtype', 'category.events_enabled', 'topicFirstPost', 'topic.event', 'canCreateEvent')
      showEventControls(subtype, categoryEnabled, topicFirstPost, event, canCreateEvent) {
        return topicFirstPost && (subtype === 'event' || categoryEnabled || event) && canCreateEvent;
      },

      @computed('category.events_min_trust_to_create')
      canCreateEvent(minTrust) {
        const user = Discourse.User.current();
        return user.trust_level >= minTrust;
      }
    });

    ComposerBody.reopen({
      @observes('composer.event')
      resizeWhenEventAdded: function() {
        this.resize();
      },

      @observes('composer.showEventControls', 'composer.composeState')
      applyEventInlineClass() {
        Ember.run.scheduleOnce('afterRender', this, () => {
          const showEventControls = this.get('composer.showEventControls');
          const $container = $('.composer-fields .title-and-category');

          $container.toggleClass('show-event-controls', Boolean(showEventControls));

          if (showEventControls) {
            const $anchor = this.site.mobileView ? $container.find('.title-input') : $container;
            $('.composer-controls-event').appendTo($anchor);
          }

          this.resize();
        });
      }
    });

    Topic.reopen({
      @computed('subtype', 'category.events_enabled', 'canCreateEvent')
      showEventControls(subtype, categoryEnabled, canCreateEvent) {
        return (subtype === 'event' || categoryEnabled) && canCreateEvent;
      },

      @computed('category.events_min_trust_to_create')
      canCreateEvent(minTrust) {
        const user = Discourse.User.current();
        return user.trust_level >= minTrust;
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
          items = items.reject((item) => item.name === 'agenda' || item.name === 'calendar');

          if (category.events_agenda_enabled) {
            items.push(Discourse.NavItem.fromText('agenda', args));
          }
          if (category.events_calendar_enabled) {
            items.push(Discourse.NavItem.fromText('calendar', args));
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
      },

      @on('didInsertElement')
      moveRsvp() {
        Ember.run.scheduleOnce('afterRender', () => {
          this.$('.topic-list-event-rsvp').insertAfter(this.$('.link-top-line'));
        })
      }
    });

    EditCategorySettings.reopen({
      @computed('category')
      availableViews(category) {
        let views = this._super(...arguments);

        if (category.get('events_agenda_enabled')) {
          views.push({name: I18n.t('filters.agenda.title'), value: 'agenda'});
        }

        if (category.get('events_calendar_enabled')) {
          views.push({name: I18n.t('filters.calendar.title'), value: 'calendar'});
        }

        return views;
      },
    });

    const calendarRoutes = [
      `Calendar`,
      `CalendarCategory`,
      `CalendarParentCategory`,
      `CalendarCategoryNone`
    ];

    calendarRoutes.forEach((route) => {
      var route = container.lookup(`route:discovery.${route}`);
      route.reopen({
        beforeModel(transition) {
          const routeName = this.routeName;
          const queryParams = this.paramsFor(routeName);

          if (!queryParams.start || !queryParams.end) {
            const month = moment().month();
            const year = moment().year();
            const { start, end } = calendarRange(month, year);

            // abort is necessary here because of https://github.com/emberjs/ember.js/issues/12169
            transition.abort();
            this.transitionTo(`${transition.intent.url}?start=${start}&end=${end}`);
          }

          this._super(transition);
        },

        renderTemplate(controller, model) {
          // respect discourse-layouts settings
          const global = siteSettings.layouts_list_navigation_disabled_global;
          const catGlobal = model.category && model.category.get('layouts_list_navigation_disabled_global');
          if (!global && !catGlobal) {
            if (this.routeName.indexOf('Category') > -1) {
              this.render('navigation/category', { outlet: 'navigation-bar' });
            } else {
              this.render('navigation/default', { outlet: 'navigation-bar' });
            }
          }
          this.render("discovery/calendar", { outlet: "list-container", controller: 'discovery/topics' });
        }
      });
    });

    const categoryRoutes = [
      'category',
      'parentCategory',
      'categoryNone'
    ];

    categoryRoutes.forEach(function(route){
      withPluginApi('0.8.12', api => {
        api.modifyClass(`route:discovery.${route}`, {
          afterModel(model) {
            const filter = this.filter(model.category);
            if (filter === 'calendar' || filter === 'agenda') {
              return this.replaceWith(`/c/${Discourse.Category.slugFor(model.category)}/l/${this.filter(model.category)}`);
            } else {
              return this._super(...arguments);
            }
          }
        });
      });
    });

    withPluginApi('0.8.12', api => {
      api.addDiscoveryQueryParam('end', { replace: true, refreshModel: true });
      api.addDiscoveryQueryParam('start', { replace: true, refreshModel: true });

      api.modifyClass('controller:preferences/interface', {
        @computed("makeThemeDefault")
        saveAttrNames(makeDefault) {
          let attrs = this._super(makeDefault);
          attrs.push('custom_fields');
          return attrs;
        },
      });

      if (siteSettings.events_hamburger_menu_calendar_link) {
        api.decorateWidget('hamburger-menu:generalLinks', helper => {
          return {
            route: 'discovery.calendar',
            className: 'calendar-link',
            label: 'filters.calendar.title'
          }
        })
      }

      if (siteSettings.events_hamburger_menu_agenda_link) {
        api.decorateWidget('hamburger-menu:generalLinks', helper => {
          return {
            route: 'discovery.agenda',
            className: 'agenda-link',
            label: 'filters.agenda.title'
          }
        })
      }

      const user = api.getCurrentUser();
      if (user && user.admin) {
        api.modifyClass('model:site-setting', {
          allowsNone: function() {
            if (this.get('setting') === 'events_timezone_default') {
              return 'site_settings.events_timezone_default_placeholder';
            } else {
              this._super();
            }
          }.property('valid_values')
        })
      }

      api.modifyClass('controller:topic', {
        @observes('model.id')
        subscribeCalendarEvents() {
          this.unsubscribeCalendarEvents();

          this.messageBus.subscribe(`/calendar-events/${this.get('model.id')}`, data => {
            const topic = this.get('model');
            const currentUser = this.get('currentUser');

            if (data.current_user_id === currentUser.id) return;

            switch (data.type) {
              case "rsvp": {
                let prop = Object.keys(data).filter((p) => p.indexOf('event_') > -1);
                this.set(`model.${prop}`, data[prop]);
                this.notifyPropertyChange(`model.${prop}`);
              }
            }
          })
        },

        unsubscribeCalendarEvents() {
          this.messageBus.unsubscribe(`/calendar-events/${this.get('model.id')}`);
        }
      })
    });
  }
};
