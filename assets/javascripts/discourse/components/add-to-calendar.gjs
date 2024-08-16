import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import DropdownMenu from "discourse/components/dropdown-menu";
import i18n from "discourse-common/helpers/i18n";
import DMenu from "float-kit/components/d-menu";
import { googleUri, icsUri } from "../lib/date-utilities";

export default class AddToCalendar extends Component {
  @service site;

  get calendarUris() {
    const topic = this.args.topic;

    let params = {
      event: topic.event,
      title: topic.title,
      url: window.location.hostname + topic.get("url"),
    };

    if (topic.location && topic.location.geo_location) {
      params.location = topic.location.geo_location.address;
    }

    return [
      { uri: googleUri(params), label: "google" },
      { uri: icsUri(params), label: "ics" },
    ];
  }

  <template>
    <DMenu
      @identifier="add-to-calendar"
      @icon="far-calendar-plus"
      @label={{i18n "add_to_calendar.label"}}
      @autofocus={{true}}
    >
      <:trigger>
        {{yield}}
      </:trigger>

      <:content>
        <DropdownMenu as |dropdown|>
          <dropdown.item class="add-to-calendar-item">
            {{#each this.calendarUris as |c|}}
              <DButton
                @label={{concat "add_to_calendar." c.label}}
                @href={{c.uri}}
                rel="noopener noreferrer"
                target="_blank"
              />
            {{/each}}
          </dropdown.item>
        </DropdownMenu>
      </:content>
    </DMenu>
  </template>
}
