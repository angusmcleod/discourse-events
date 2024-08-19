import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { eventLabel } from "../lib/date-utilities";
import AddEvent from "./modal/add-event";

export default class AddToCalendar extends Component {
  @service modal;
  @service siteSettings;
  @tracked event = this.args.event;

  get valueClasses() {
    let classes = "add-event";
    if (this.args.noText) {
      classes += " btn-primary";
    }
    return classes;
  }

  get valueLabel() {
    return eventLabel(this.event, {
      noText: this.args.noText,
      noContainer: true,
      useEventTimezone: true,
      showRsvp: true,
      siteSettings: this.siteSettings,
    });
  }

  get iconOnly() {
    return (
      this.args.noText ||
      this.siteSettings.events_event_label_no_text ||
      Boolean(
        this.args.category &&
          this.args.category.custom_fields.events_event_label_no_text
      )
    );
  }

  @action
  showAddEvent() {
    this.modal.show(AddEvent, {
      model: {
        bufferedEvent: this.event,
        event: this.event,
        update: (event) => {
          this.event = event;
          this.args.updateEvent(event);
        },
      },
    });
  }

  @action
  removeEvent() {
    this.event = null;
    this.args.updateEvent(null);
  }

  <template>
    <div class="add-event-controls">
      {{#if this.event}}
        <DButton
          @action={{this.showAddEvent}}
          @class={{this.valueClasses}}
          @translatedLabel={{this.valueLabel}}
        />
        {{#unless @noText}}
          <DButton @icon="times" @action={{this.removeEvent}} @class="remove" />
        {{/unless}}
      {{else}}
        {{#if @iconOnly}}
          <DButton
            @icon={{this.siteSettings.events_event_label_icon}}
            @action={{this.showAddEvent}}
            @class="add-event"
            @title="add_event.btn_label"
          />
        {{else}}
          <DButton
            @icon={{this.siteSettings.events_event_label_icon}}
            @action={{this.showAddEvent}}
            @class="add-event"
            @title="add_event.btn_label"
            @label="add_event.btn_label"
          />
        {{/if}}
      {{/if}}
    </div>
  </template>
}
