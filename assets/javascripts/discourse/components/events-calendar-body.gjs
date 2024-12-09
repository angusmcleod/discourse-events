import Component from "@glimmer/component";
import { firstDayOfWeek } from "../lib/date-utilities";
import EventsCalendarDay from "./events-calendar-day";

export default class EventsCalendarBody extends Component {
  get weekdays() {
    let data = moment.localeData();
    let weekdays = this.args.responsive ? data.weekdaysMin() : data.weekdays();
    let firstDay = firstDayOfWeek();

    // Create a copy of the array before splicing to avoid modifying the original
    weekdays = [...weekdays];

    // If firstDay is not 0 (Sunday), rotate the array
    if (firstDay > 0) {
      let beforeFirst = weekdays.splice(0, firstDay);
      weekdays.push(...beforeFirst);
    }

    return weekdays;
  }

  <template>
    <div class="events-calendar-body">
      {{#each this.weekdays as |weekday|}}
        <div class="weekday">
          <span>{{weekday}}</span>
        </div>
      {{/each}}

      {{#each @days as |day index|}}
        <EventsCalendarDay
          @day={{day}}
          @currentDate={{@currentDate}}
          @currentMonth={{@currentMonth}}
          @selectDate={{@selectDate}}
          @canSelectDate={{@canSelectDate}}
          @showEvents={{@showEvents}}
          @topics={{@topics}}
          @responsive={{@responsive}}
          @index={{index}}
        />
      {{/each}}
    </div>
  </template>
}
