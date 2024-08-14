import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import Category from "discourse/models/category";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { default as Timezones } from "../fixtures/timezone-fixtures";

acceptance("Events | Composer", function (needs) {
  needs.user();
  needs.site({
    event_timezones: Timezones["event_timezones"],
  });

  test("not in an events category", async function (assert) {
    this.siteSettings.events_enabled = true;
    await visit("/");
    await click("#create-topic");

    assert.ok(
      !exists("#reply-control .add-event"),
      "the add-event button is not visible"
    );
  });

  test("in an events category", async function (assert) {
    this.siteSettings.events_enabled = true;
    Category.findById(2).set("events_enabled", true);

    await visit("/");
    await click("#create-topic");

    const categoryChooser = selectKit("#reply-control .category-chooser");
    await categoryChooser.expand();
    await categoryChooser.selectRowByValue(2);

    assert.ok(
      exists("#reply-control .add-event"),
      "the add-event button is visible"
    );

    await click(".add-event");

    assert.ok(exists(".add-event-modal"), "the add-event-modal is visible");

    const tzChooser = selectKit("#add-event-select-timezone");
    await tzChooser.expand();
    await tzChooser.selectRowByValue("Australia/Perth");

    await fillIn(".start-card .date-picker", "2024-08-13");

    const startTimeChooser = selectKit(".start-card .d-time-input .combo-box");
    await startTimeChooser.expand();
    await startTimeChooser.selectRowByValue(1200);

    await click(".d-modal__footer .btn-primary");

    assert.strictEqual(
      query("#reply-control .add-event .date").innerText.trim(),
      "August 13th, 20:00, (GMT+08:00) Perth",
      "the add-event button has the right datetime"
    );
  });

  test("when the plugin is disabled", async function (assert) {
    this.siteSettings.events_enabled = false;
    Category.findById(2).set("events_enabled", true);

    await visit("/");
    await click("#create-topic");

    const categoryChooser = selectKit("#reply-control .category-chooser");
    await categoryChooser.expand();
    await categoryChooser.selectRowByValue(2);

    assert.ok(
      !exists("#reply-control .add-event"),
      "the add-event button is not visible"
    );
  });
});
