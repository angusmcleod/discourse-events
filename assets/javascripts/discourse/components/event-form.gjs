import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { hash } from "rsvp";
import DateInput from "discourse/components/date-input";
import InputTip from "discourse/components/input-tip";
import TimeInput from "discourse/components/time-input";
import concatClass from "discourse/helpers/concat-class";
import i18n from "discourse-common/helpers/i18n";
import ComboBox from "select-kit/components/combo-box";
import EmailGroupUserChooser from "select-kit/components/email-group-user-chooser";
import {
  compileEvent,
  nextInterval,
  setupEventForm,
  timezoneLabel,
} from "../lib/date-utilities";

export default class EventForm extends Component {
  @service siteSettings;
  @service site;
  @tracked endEnabled = false;
  @tracked allDay = false;
  @tracked deadline = false;
  @tracked showTimezone = false;
  @tracked startDate;
  @tracked startTime;
  @tracked endDate;
  @tracked endTime;
  @tracked timezone;
  @tracked rsvpEnabled = false;
  @tracked goingMax;
  @tracked usersGoing;

  constructor() {
    super(...arguments);
    this.setupProperties();
  }

  setupProperties() {
    const props = setupEventForm(this.args.event, {
      siteSettings: this.siteSettings,
    });
    Object.assign(this, props);
    if (
      this.siteSettings.events_add_default_end_time &&
      !this.args.event &&
      !this.endDate &&
      !this.endTime
    ) {
      this.endEnabled = true;
    }
    if (this.siteSettings.events_deadlines) {
      this.toggleDeadlineEnabled;
    }
  }

  get timezones() {
    const eventTimezones =
      this.args.event?.eventTimezones || this.site.event_timezones;
    return eventTimezones.map((tz) => ({
      value: tz.value,
      name: timezoneLabel(tz.value, { siteSettings: this.siteSettings }),
    }));
  }

  get showDeadlineToggle() {
    return this.siteSettings.events_deadlines;
  }

  @action
  onChangeStartDate(date) {
    this.startDate = moment(date);
    this.updateEvent();
  }

  @action
  onChangeEndDate(date) {
    this.endDate = moment(date);
    this.updateEvent();
  }

  @action
  onChangeStartTime(time) {
    this.startTime = moment(time);
    this.updateEvent();
  }

  @action
  onChangeEndTime(time) {
    this.endTime = moment(time);
    this.updateEvent();
  }

  @action
  toggleEndEnabled(event) {
    this.endEnabled = event.target.checked;
    if (this.endEnabled) {
      if (!this.endDate) {
        this.endDate = this.startDate;
      }
      if (!this.allDay && !this.endTime) {
        const start = moment(
          `${moment(this.startDate).format(
            "YYYY-MM-DD"
          )} ${this.startTime.format("HH:mm")}`
        );
        this.endTime = moment(start).add(1, "hours");
      }
    } else {
      this.endDate = undefined;
      this.endTime = undefined;
    }
    this.updateEvent();
  }

  @action
  toggleAllDay(event) {
    this.allDay = event.target.checked;
    if (!this.allDay) {
      const start = nextInterval();
      this.startTime = start;
      if (this.endEnabled) {
        this.endTime = moment(start).add(1, "hours");
      }
    }
    this.updateEvent();
  }

  @action
  toggleDeadline(event) {
    this.deadline = event.target.checked;
    this.updateEvent();
  }

  @action
  updateTimezone(newTimezone) {
    this.timezone = newTimezone;
    this.updateEvent();
  }

  @action
  updateUsersGoing(usersGoing) {
    this.usersGoing = usersGoing;
    this.updateEvent();
  }

  @action
  updateGoingMax(goingMax) {
    this.goingMax = goingMax;
    this.updateEvent();
  }

  @action
  updateRsvpEnabled(rsvpEnabled) {
    this.rsvpEnabled = rsvpEnabled;
    this.updateEvent();
  }

  @action
  updateEvent() {
    const event = compileEvent({
      startDate: this.startDate,
      startTime: this.startTime,
      endDate: this.endDate,
      endTime: this.endTime,
      endEnabled: this.endEnabled,
      allDay: this.allDay,
      deadline: this.deadline,
      timezone: this.timezone,
      rsvpEnabled: this.rsvpEnabled,
      goingMax: this.goingMax,
      usersGoing: this.usersGoing,
    });
    this.args.updateEvent(event, this.eventValid(event));
  }

  @action
  eventValid(event) {
    return !event || !event.end || moment(event.end).isSameOrAfter(event.start);
  }
  <template>
    <div class="event-form">
      <div class="event-controls">
        <div class="control">
          <Input
            @type="checkbox"
            @checked={{this.endEnabled}}
            {{on "change" this.toggleEndEnabled}}
          />
          <span>{{i18n "add_event.end_enabled"}}</span>
        </div>

        <div class="control">
          <Input
            @type="checkbox"
            @checked={{this.allDay}}
            {{on "change" this.toggleAllDay}}
          />
          <span>{{i18n "add_event.all_day"}}</span>
        </div>

        {{#if this.showDeadlineToggle}}
          <div class="control deadline">
            <Input
              @type="checkbox"
              @checked={{this.deadline}}
              title={{i18n "add_event.deadline.title"}}
              {{on "click" this.toggleDeadline}}
            />
            <span title={{i18n "add_event.deadline.title"}}>{{i18n
                "add_event.deadline.label"
              }}</span>
          </div>
        {{/if}}

        {{#unless this.allDay}}
          <div class="control full-width">
            <ComboBox
              @id="add-event-select-timezone"
              @value={{this.timezone}}
              @valueProperty="value"
              @onChange={{this.updateTimezone}}
              @content={{this.timezones}}
              @options={{hash filterable=true none="add_event.no_timezone"}}
            />
          </div>
        {{/unless}}
      </div>

      <div class="datetime-controls">
        <div class="start-card date-time-card">
          <span class="sub-title">
            {{i18n "add_event.event_start"}}
          </span>

          <InputTip @validation={{this.startDateTimeValidation}} />

          <div class="date-time-set">
            <div class="date-area">
              <label class="input-group-label">
                {{i18n "add_event.event_date"}}
              </label>

              <DateInput
                @date={{this.startDate}}
                @onChange={{this.onChangeStartDate}}
                @useGlobalPickerContainer={{true}}
              />
            </div>

            {{#unless this.allDay}}
              <div class="time-area">
                <label class="input-group-label">
                  {{i18n "add_event.event_time"}}
                </label>

                <TimeInput
                  @date={{this.startTime}}
                  @onChange={{this.onChangeStartTime}}
                />
              </div>
            {{/unless}}
          </div>
        </div>

        <div
          class={{concatClass
            "end-card date-time-card"
            (unless this.endEnabled "disabled")
          }}
        >
          <span class="sub-title">
            {{i18n "add_event.event_end"}}
          </span>

          <InputTip @validation={{this.scheduleDateTimeValidation}} />

          <div class="date-time-set">
            <div class="date-area">
              <label class="input-group-label">
                {{i18n "add_event.event_date"}}
              </label>

              <DateInput
                @date={{this.endDate}}
                @onChange={{this.onChangeEndDate}}
                @useGlobalPickerContainer={{true}}
              />
            </div>

            {{#unless this.allDay}}
              <div class="time-area">
                <label class="input-group-label">
                  {{i18n "add_event.event_time"}}
                </label>

                <TimeInput
                  @date={{this.endTime}}
                  @onChange={{this.onChangeEndTime}}
                />
              </div>
            {{/unless}}
          </div>
        </div>
      </div>

      {{#if this.siteSettings.events_rsvp}}
        <div class="rsvp-controls">
          <div class="control">
            <Input
              @type="checkbox"
              @checked={{this.rsvpEnabled}}
              {{on "change" (fn this.updateRsvpEnabled this.rsvpEnabled)}}
            />
            <span>{{i18n "add_event.rsvp_enabled"}}</span>
          </div>

          {{#if this.rsvpEnabled}}
            <div class="rsvp-container">
              <div class="control">
                <span>{{i18n "add_event.going_max"}}</span>
                <Input
                  @type="number"
                  @value={{this.goingMax}}
                  {{on "change" (fn this.updateGoingMax this.goingMax)}}
                />
              </div>

              <div class="control full-width">
                <span>{{i18n "add_event.going"}}</span>
                <EmailGroupUserChooser
                  @value={{this.usersGoing}}
                  @onChange={{this.updateUsersGoing}}
                  class="user-selector"
                  @options={{hash
                    filterPlaceholder="composer.users_placeholder"
                  }}
                />
              </div>
            </div>
          {{/if}}
        </div>
      {{/if}}
    </div>
  </template>
}
