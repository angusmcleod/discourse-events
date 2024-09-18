import { render } from "@ember/test-helpers";
import hbs from "htmlbars-inline-precompile";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import { query } from "discourse/tests/helpers/qunit-helpers";
import I18n from "discourse-i18n";
import { default as Timezones } from "../fixtures/timezone-fixtures";

module("Poll | Component | event-form", function (hooks) {
  setupRenderingTest(hooks);

  test("open the form without a defined event", async function (assert) {
    this.siteSettings.events_support_deadlines = true;
    this.site.event_timezones = Timezones["event_timezones"];
    this.setProperties({
      event: {
        deadline: true,
      },
      updateEvent: () => {},
    });

    await render(hbs`<EventForm
      @event={{this.event}}
      @updateEvent={{this.updateEvent}}
    />`);

    assert.strictEqual(
      query(".event-form .control.deadline span").textContent.trim(),
      I18n.t("add_event.deadline.label"),
      "displays the deadline checkbox"
    );

    assert.strictEqual(
      query(".event-form .control.deadline input").checked,
      true,
      "the checkbox is checked"
    );
  });
});
