import Category from "discourse/models/category";
import {
  default as discourseComputed,
  observes,
  on,
} from "discourse-common/utils/decorators";
import DiscourseURL from "discourse/lib/url";
import { withPluginApi } from "discourse/lib/plugin-api";
import { CREATE_TOPIC } from "discourse/models/composer";
import { bind, scheduleOnce } from "@ember/runloop";
import EmberObject from "@ember/object";
import I18n from "I18n";

export default {
  name: "events-edits",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    const currentUser = container.lookup("current-user:main");

    withPluginApi("1.4.0", (api) => {
      api.serializeToDraft("event");
      api.serializeOnCreate("event");
      api.serializeToTopic("event", "topic.event");

      api.addDiscoveryQueryParam("end", { replace: true, refreshModel: true });
      api.addDiscoveryQueryParam("start", {
        replace: true,
        refreshModel: true,
      });

      api.modifyClass("model:composer", {
        pluginId: "events",

        @discourseComputed(
          "subtype",
          "category.events_enabled",
          "topicFirstPost",
          "topic.event",
          "canCreateEvent"
        )
        showEventControls(
          subtype,
          categoryEnabled,
          topicFirstPost,
          event,
          canCreateEvent
        ) {
          return (
            topicFirstPost &&
            (subtype === "event" || categoryEnabled || event) &&
            canCreateEvent
          );
        },

        @discourseComputed("category.events_min_trust_to_create")
        canCreateEvent(minTrust) {
          return currentUser.staff || currentUser.trust_level >= minTrust;
        },
      });

      api.modifyClass("component:composer-body", {
        pluginId: "events",

        @observes("composer.event")
        resizeWhenEventAdded() {
          this.composerResized();
        },

        @observes("composer.showEventControls", "composer.composeState")
        applyEventInlineClass() {
          scheduleOnce("afterRender", this, () => {
            const showEventControls = this.get("composer.showEventControls");
            const $container = $(".composer-fields .title-and-category");

            $container.toggleClass(
              "show-event-controls",
              Boolean(showEventControls)
            );

            if (showEventControls) {
              const $anchor = this.site.mobileView
                ? $container.find(".title-input")
                : $container;
              $(".composer-controls-event").appendTo($anchor);
            }

            this.composerResized();
          });
        },
      });

      api.modifyClass("model:topic", {
        pluginId: "events",

        @discourseComputed(
          "subtype",
          "category.events_enabled",
          "canCreateEvent"
        )
        showEventControls(subtype, categoryEnabled, canCreateEvent) {
          return (subtype === "event" || categoryEnabled) && canCreateEvent;
        },

        @discourseComputed("category.events_min_trust_to_create")
        canCreateEvent(minTrust) {
          return currentUser.staff || currentUser.trust_level >= minTrust;
        },

        @discourseComputed("last_read_post_number", "highest_post_number")
        topicListItemClasses(lastRead, highest) {
          let classes = "date-time title raw-link event-link raw-topic-link";
          if (lastRead === highest) {
            classes += " visited";
          }
          return classes;
        },
      });

      // necessary because topic-title plugin outlet only recieves model
      api.modifyClass("controller:topic", {
        pluginId: "events",

        @observes("editingTopic")
        setEditingTopicOnModel() {
          this.set("model.editingTopic", this.get("editingTopic"));
        },
      });

      api.addNavigationBarItem({
        name: "calendar",
        displayName: "Calendar",
        customFilter: (category) => {
          return (
            siteSettings.events_calendar_enabled ||
            (category && category.events_calendar_enabled)
          );
        },
        customHref: (category) => {
          if (category) {
            return `${category.url}/l/calendar`;
          } else {
            return "/calendar";
          }
        },
      });

      api.addNavigationBarItem({
        name: "agenda",
        displayName: "Agenda",
        customFilter: (category) => {
          return (
            siteSettings.events_agenda_enabled ||
            (category && category.events_agenda_enabled)
          );
        },
        customHref: (category) => {
          if (category) {
            return `${category.url}/l/agenda`;
          } else {
            return "/agenda";
          }
        },
      });

      api.modifyClass("component:topic-list-item", {
        pluginId: "events",

        @on("didInsertElement")
        setupEventLink() {
          scheduleOnce("afterRender", this, () => {
            $(".event-link", this.element).on(
              "click",
              bind(this, this.handleEventLabelClick)
            );
          });
        },

        @on("willDestroyElement")
        teardownEventLink() {
          $(".event-link", this.element).off(
            "click",
            bind(this, this.handleEventLabelClick)
          );
        },

        handleEventLabelClick(e) {
          e.preventDefault();
          const topic = this.get("topic");
          const href = $(e.target).attr("href");
          this.appEvents.trigger("header:update-topic", topic);
          DiscourseURL.routeTo(href);
        },

        @on("didRender")
        moveElements() {
          const topic = this.get("topic");

          scheduleOnce("afterRender", () => {
            const $linkTopLine = $(".link-top-line", this.element);
            let rowBelowTitle = false;

            if (topic.event && topic.event.rsvp) {
              $(".topic-list-event-rsvp", this.element).insertAfter(
                $linkTopLine
              );
              rowBelowTitle = true;
            }

            if (this.siteSettings.events_event_label_short_after_title) {
              $(".date-time-container", this.element).insertAfter($linkTopLine);
              rowBelowTitle = true;
            }

            if (rowBelowTitle) {
              $(".main-link", this.element).addClass("row-below-title");
            }
          });
        },
      });

      api.modifyClass("component:edit-category-settings", {
        pluginId: "events",

        @discourseComputed("category")
        availableViews(category) {
          let views = this._super(...arguments);

          if (category.get("custom_fields.events_agenda_enabled")) {
            views.push({
              name: I18n.t("filters.agenda.title"),
              value: "agenda",
            });
          }

          if (category.get("custom_fields.events_calendar_enabled")) {
            views.push({
              name: I18n.t("filters.calendar.title"),
              value: "calendar",
            });
          }

          return views;
        },
      });

      const categoryRoutes = ["category", "categoryNone"];

      categoryRoutes.forEach(function (route) {
        api.modifyClass(`route:discovery.${route}`, {
          pluginId: "events",

          afterModel(model) {
            const filter = this.filter(model.category);
            if (filter === "calendar" || filter === "agenda") {
              return this.replaceWith(
                `/c/${Category.slugFor(model.category)}/l/${this.filter(
                  model.category
                )}`
              );
            } else {
              return this._super(...arguments);
            }
          },
        });
      });

      api.modifyClass("controller:preferences/interface", {
        pluginId: "events",

        @discourseComputed("makeThemeDefault")
        saveAttrNames(makeDefault) {
          let attrs = this._super(makeDefault);
          attrs.push("custom_fields");
          return attrs;
        },
      });

      if (siteSettings.events_hamburger_menu_calendar_link) {
        api.decorateWidget("hamburger-menu:generalLinks", () => {
          return {
            route: "discovery.calendar",
            className: "calendar-link",
            label: "filters.calendar.title",
          };
        });
      }

      if (siteSettings.events_hamburger_menu_agenda_link) {
        api.decorateWidget("hamburger-menu:generalLinks", () => {
          return {
            route: "discovery.agenda",
            className: "agenda-link",
            label: "filters.agenda.title",
          };
        });
      }

      const user = api.getCurrentUser();
      if (user && user.admin) {
        api.modifyClass("model:site-setting", {
          pluginId: "events",

          @discourseComputed("valid_values")
          allowsNone() {
            if (this.get("setting") === "events_timezone_default") {
              return "site_settings.events_timezone_default_placeholder";
            } else {
              this._super();
            }
          },
        });
      }

      api.modifyClass("controller:topic", {
        pluginId: "events",

        @observes("model.id")
        subscribeDiscourseEvents() {
          this.unsubscribeDiscourseEvents();

          this.messageBus.subscribe(
            `/discourse-events/${this.get("model.id")}`,
            (data) => {
              if (data.current_user_id === currentUser.id) {
                return;
              }

              switch (data.type) {
                case "rsvp": {
                  let prop = Object.keys(data).filter(
                    (p) => p.indexOf("event") > -1
                  );
                  if (prop && prop[0]) {
                    let key = prop[0].split("_").join(".");
                    this.set(`model.${key}`, data[prop[0]]);
                    this.notifyPropertyChange(`model.${prop}`);
                  }
                }
              }
            }
          );
        },

        unsubscribeDiscourseEvents() {
          this.messageBus.unsubscribe(
            `/discourse-events/${this.get("model.id")}`
          );
        },
      });

      api.modifyClass("controller:composer", {
        pluginId: "events",

        @discourseComputed(
          "model.action",
          "model.event",
          "model.category.events_required",
          "lastValidatedAt"
        )
        eventValidation(action, event, eventsRequired, lastValidatedAt) {
          if (action === CREATE_TOPIC && eventsRequired && !event) {
            return EmberObject.create({
              failed: true,
              reason: I18n.t("composer.error.event_missing"),
              lastShownAt: lastValidatedAt,
            });
          }
        },

        @observes("model.composeState")
        ensureEvent() {
          if (
            this.model &&
            this.model.topic &&
            this.model.topic.event &&
            !this.model.event
          ) {
            this.set("model.event", this.model.topic.event);
          }
        },

        // overriding cantSubmitPost on the model is more fragile
        save() {
          if (!this.get("eventValidation")) {
            this._super(...arguments);
          } else {
            this.set("lastValidatedAt", Date.now());
          }
        },
      });

      api.includePostAttributes("connected_event", "connected_event");

      api.addPostClassesCallback((attrs) => {
        if (attrs.post_number === 1 && attrs.connected_event) {
          return ["for-event"];
        }
      });

      api.decorateWidget("post-menu:before-extra-controls", (helper) => {
        const post = helper.getModel();

        if (post.connected_event && post.connected_event.can_manage) {
          return helper.attach("link", {
            attributes: {
              target: "_blank",
            },
            href: post.connected_event.admin_url,
            className: "manage-event",
            icon: "external-link-alt",
            label: "post.event.manage.label",
            title: "post.event.manage.title",
          });
        }
      });
    });
  },
};
