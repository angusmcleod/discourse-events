import Component from "@glimmer/component";
import { firstDayOfWeek } from "../lib/date-utilities";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";

export default class EventsCalendarBody extends Component {
  @service currentUser;
  @tracked firstDayOfWeek = this.currentUser.custom_fields.calendar_first_day_week;

  get weekdays() {
    let data = moment.localeData();
    let weekdays = this.args.responsive ? data.weekdaysMin() : data.weekdays();
    let firstDay = this.firstDayOfWeek;
    let beforeFirst = weekdays.splice(0, firstDay);
    weekdays.push(...beforeFirst);
    return weekdays;
  }

  @action
  updateFirstDayOfWeek() {
    this.firstDayOfWeek = this.currentUser.custom_fields.calendar_first_day_week;
  }

  constructor() {
    super(...arguments);
    this.currentUser.addObserver('custom_fields.calendar_first_day_week', this, this.updateFirstDayOfWeek);
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.currentUser.removeObserver('custom_fields.calendar_first_day_week', this, this.updateFirstDayOfWeek);
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
