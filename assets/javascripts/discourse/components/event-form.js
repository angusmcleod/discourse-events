import Component from "@ember/component";
import {
  default as discourseComputed,
  observes,
} from "discourse-common/utils/decorators";
import {
  compileEvent,
  nextInterval,
  setupEventForm,
  timezoneLabel,
} from "../lib/date-utilities";

export default Component.extend({
  classNames: "event-form",
  endEnabled: false,
  allDay: false,
  showTimezone: false,

  didReceiveAttrs() {
    this._super(...arguments);
    const props = setupEventForm(this.event, {
      siteSettings: this.siteSettings,
    });
    this.setProperties(props);
    if (
      this.siteSettings.events_add_default_end_time &&
      !this.event &&
      !this.endDate &&
      !this.endTime
    ) {
      this.send("toggleEndEnabled", true);
    }
  },

  eventValid(event) {
    return !event || !event.end || moment(event.end).isSameOrAfter(event.start);
  },

  @observes(
    "startDate",
    "startTime",
    "endDate",
    "endTime",
    "endEnabled",
    "allDay",
    "timezone",
    "rsvpEnabled",
    "goingMax",
    "usersGoing"
  )
  eventUpdated() {
    let event = compileEvent({
      startDate: this.startDate,
      startTime: this.startTime,
      endDate: this.endDate,
      endTime: this.endTime,
      endEnabled: this.endEnabled,
      allDay: this.allDay,
      timezone: this.timezone,
      rsvpEnabled: this.rsvpEnabled,
      goingMax: this.goingMax,
      usersGoing: this.usersGoing,
    });
    this.updateEvent(event, this.eventValid(event));
  },

  @discourseComputed()
  timezones() {
    const eventTimezones =
      this.get("eventTimezones") || this.site.event_timezones;
    return eventTimezones.map((tz) => {
      return {
        value: tz.value,
        name: timezoneLabel(tz.value, { siteSettings: this.siteSettings }),
      };
    });
  },

  @discourseComputed("endEnabled")
  endClass(endEnabled) {
    return endEnabled ? "" : "disabled";
  },

  actions: {
    onChangeStartDate(date) {
      this.set("startDate", moment(date));
    },

    onChangeEndDate(date) {
      this.set("endDate", moment(date));
    },

    onChangeStartTime(time) {
      this.set("startTime", moment(time));
    },

    onChangeEndTime(time) {
      this.set("endTime", moment(time));
    },

    toggleEndEnabled(value) {
      this.set("endEnabled", value);

      if (value) {
        if (!this.endDate) {
          this.set("endDate", this.startDate);
        }

        if (!this.allDay) {
          if (!this.endTime) {
            let start = moment(
              moment(this.startDate).format("YYYY-MM-DD") +
                " " +
                this.startTime.format("HH:mm")
            );
            this.set("endTime", moment(start).add(1, "hours"));
          }
        }
      } else {
        this.setProperties({
          endDate: undefined,
          endTime: undefined,
        });
      }
    },

    toggleAllDay(value) {
      this.set("allDay", value);

      if (!value) {
        const start = nextInterval();
        this.set("startTime", start);

        if (this.endEnabled) {
          this.set("endTime", moment(start).add(1, "hours"));
        }
      }
    },
  },
});
