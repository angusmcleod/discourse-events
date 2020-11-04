import Composer from 'discourse/models/composer';
import Category from 'discourse/models/category';
import ComposerBody from 'discourse/components/composer-body';
import Topic from 'discourse/models/topic';
import TopicController from 'discourse/controllers/topic';
import { default as discourseComputed, observes, on } from 'discourse-common/utils/decorators';
import NavItem from 'discourse/models/nav-item';
import EditCategorySettings from 'discourse/components/edit-category-settings';
import TopicListItem from 'discourse/components/topic-list-item';
import DiscourseURL from 'discourse/lib/url';
import { withPluginApi } from 'discourse/lib/plugin-api';
import { calendarRange, firstDayOfWeek } from '../lib/date-utilities';
import { CREATE_TOPIC } from "discourse/models/composer";
import { scheduleOnce, bind } from "@ember/runloop";
import EmberObject from "@ember/object";
import I18n from "I18n";

export default {
  name: 'events-edits',
  initialize(container) {
    const siteSettings = container.lookup('site-settings:main');

    Composer.serializeOnCreate('event');
    Composer.serializeToTopic('event', 'topic.event');

    Composer.reopen({
      @discourseComputed('subtype', 'category.events_enabled', 'topicFirstPost', 'topic.event', 'canCreateEvent')
      showEventControls(subtype, categoryEnabled, topicFirstPost, event, canCreateEvent) {
        return topicFirstPost && (subtype === 'event' || categoryEnabled || event) && canCreateEvent;
      },

      @discourseComputed('category.events_min_trust_to_create')
      canCreateEvent(minTrust) {
        const user = Discourse.User.current();
        return user.staff || user.trust_level >= minTrust;
      }
    });

    ComposerBody.reopen({
      @observes('composer.event')
      resizeWhenEventAdded: function() {
        this.resize();
      },

      @observes('composer.showEventControls', 'composer.composeState')
      applyEventInlineClass() {
        scheduleOnce('afterRender', this, () => {
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
      @discourseComputed('subtype', 'category.events_enabled', 'canCreateEvent')
      showEventControls(subtype, categoryEnabled, canCreateEvent) {
        return (subtype === 'event' || categoryEnabled) && canCreateEvent;
      },

      @discourseComputed('category.events_min_trust_to_create')
      canCreateEvent(minTrust) {
        const user = Discourse.User.current();
        return user.staff || user.trust_level >= minTrust;
      },

      @discourseComputed('last_read_post_number', 'highest_post_number')
      topicListItemClasses(lastRead, highest) {
        let classes = "date-time title raw-link event-link raw-topic-link";
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
            items.push(NavItem.fromText('agenda', args));
          }
          if (category.events_calendar_enabled) {
            items.push(NavItem.fromText('calendar', args));
          }
        }

        return items;
      }
    });

    TopicListItem.reopen({
      @on('didInsertElement')
      setupEventLink() {
        scheduleOnce('afterRender', this, () => {
          $('.event-link', this.element).on('click', bind(this, this.handleEventLabelClick));
        });
      },

      @on('willDestroyElement')
      teardownEventLink() {
        $('.event-link', this.element).off('click', bind(this, this.handleEventLabelClick));
      },

      handleEventLabelClick(e) {
        e.preventDefault();
        const topic = this.get('topic');
        const href = $(e.target).attr("href")
        this.appEvents.trigger('header:update-topic', topic);
        DiscourseURL.routeTo(href);
      },

      @on('didRender')
      moveElements() {
        const topic = this.get('topic');

        scheduleOnce('afterRender', () => {
          const $linkTopLine = $('.link-top-line', this.element);
          let rowBelowTitle = false;

          if (topic.event && topic.event.rsvp) {
            $('.topic-list-event-rsvp', this.element).insertAfter($linkTopLine);
            rowBelowTitle = true;
          }

          if (Discourse.SiteSettings.events_event_label_short_after_title) {
            $('.date-time-container', this.element).insertAfter($linkTopLine);
            rowBelowTitle = true;
          }

          if (rowBelowTitle) {
            $('.main-link', this.element).addClass('row-below-title');
          }
        });
      }
    });

    EditCategorySettings.reopen({
      @discourseComputed('category')
      availableViews(category) {
        let views = this._super(...arguments);

        if (category.get('custom_fields.events_agenda_enabled')) {
          views.push({name: I18n.t('filters.agenda.title'), value: 'agenda'});
        }

        if (category.get('custom_fields.events_calendar_enabled')) {
          views.push({name: I18n.t('filters.calendar.title'), value: 'calendar'});
        }

        return views;
      },
    });

    const calendarRoutes = [
      `Calendar`,
      `CalendarCategory`,
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
            this.setProperties({ start, end });
          }

          this._super(transition);
        },

        setupController(controller, model) {
          const start = this.get('start');
          const end = this.get('end');

          if (start || end) {
            let initialDateRange = {};
            if (start) initialDateRange['start'] = start;
            if (end) initialDateRange['end'] = end;
            this.controllerFor("discovery/topics").setProperties({ initialDateRange });
          }

          this._super(controller, model);
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
          afterModel(model, transition) {
            const filter = this.filter(model.category);
            if (filter === 'calendar' || filter === 'agenda') {
              return this.replaceWith(`/c/${Category.slugFor(model.category)}/l/${this.filter(model.category)}`);
            } else {
              return this._super(...arguments);
            }
          }
        });
      });
    });

    withPluginApi('0.8.33', api => {
      api.serializeToDraft('event');
    });

    withPluginApi('0.8.12', api => {
      api.addDiscoveryQueryParam('end', { replace: true, refreshModel: true });
      api.addDiscoveryQueryParam('start', { replace: true, refreshModel: true });

      api.modifyClass('controller:preferences/interface', {
        @discourseComputed("makeThemeDefault")
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
          };
        });
      }

      if (siteSettings.events_hamburger_menu_agenda_link) {
        api.decorateWidget('hamburger-menu:generalLinks', helper => {
          return {
            route: 'discovery.agenda',
            className: 'agenda-link',
            label: 'filters.agenda.title'
          };
        });
      }

      const user = api.getCurrentUser();
      if (user && user.admin) {
        api.modifyClass('model:site-setting', {
          @discourseComputed('valid_values')
          allowsNone() {
            if (this.get('setting') === 'events_timezone_default') {
              return 'site_settings.events_timezone_default_placeholder';
            } else {
              this._super();
            }
          }
        });
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
                let prop = Object.keys(data).filter((p) => p.indexOf('event') > -1);
                if (prop && prop[0]) {
                  let key = prop[0].split('_').join('.');
                  this.set(`model.${key}`, data[prop[0]]);
                  this.notifyPropertyChange(`model.${prop}`);
                }
              }
            }
          });
        },

        unsubscribeCalendarEvents() {
          this.messageBus.unsubscribe(`/calendar-events/${this.get('model.id')}`);
        }
      });

      api.modifyClass('controller:composer', {
        @discourseComputed('model.action', 'model.event', 'model.category.events_required', 'lastValidatedAt')
        eventValidation(action, event, eventsRequired, lastValidatedAt) {
          if (action === CREATE_TOPIC && eventsRequired && !event) {
            return EmberObject.create({
              failed: true,
              reason: I18n.t('composer.error.event_missing'),
              lastShownAt: lastValidatedAt
            });
          }
        },

        // overriding cantSubmitPost on the model is more fragile
        save(opts) {
          if (!this.get('eventValidation')) {
            this._super(...arguments);
          } else {
            this.set('lastValidatedAt', Date.now());
          }
        },
      });

    });
  }
};
