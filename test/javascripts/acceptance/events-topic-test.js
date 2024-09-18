import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import topicFixtures from "discourse/tests/fixtures/topic";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import { cloneJSON } from "discourse-common/lib/object";
import I18n from "discourse-i18n";
import { default as Timezones } from "../fixtures/timezone-fixtures";

const setupServer = (needs, attrs = {}) => {
  needs.pretender((server, helper) => {
    const topicResponse = cloneJSON(topicFixtures["/t/280/1.json"]);
    if (attrs.event) {
      topicResponse.event = attrs.event;
    }
    server.get("/t/280.json", () => helper.response(topicResponse));
  });
};

acceptance("Events | topic without an event", function (needs) {
  needs.user();
  needs.site({ event_timezones: Timezones["event_timezones"] });
  setupServer(needs);

  test("does not show event", async function (assert) {
    await visit("/t/280");

    assert.ok(!exists(".event-label"), "the event-label is not visible");
  });
});

acceptance("Events | topic with an event", function (needs) {
  needs.user();
  needs.site({ event_timezones: Timezones["event_timezones"] });
  setupServer(needs, {
    event: {
      start: "2022-11-06T12:00:00.000Z",
      timezone: "Australia/Perth",
    },
  });

  test("shows event", async function (assert) {
    this.siteSettings.events_timezone_include_in_topic_list = true;
    this.siteSettings.events_timezone_display = "event";
    await visit("/t/280");

    assert.ok(exists(".event-label"), "the event-label is visible");
    assert.strictEqual(
      query(".event-label .date").innerText.trim(),
      "November 6th, 20:00",
      "the event-label shows the right datetime"
    );
  });
});

acceptance("Events | topic with an event that is a deadline", function (needs) {
  needs.user();
  needs.site({ event_timezones: Timezones["event_timezones"] });
  setupServer(needs, {
    event: {
      start: "2022-11-06T12:00:00.000Z",
      deadline: true,
      timezone: "Australia/Perth",
    },
  });

  test("shows event", async function (assert) {
    this.siteSettings.events_timezone_include_in_topic_list = true;
    this.siteSettings.events_timezone_display = "event";
    this.siteSettings.events_support_deadlines = true;
    await visit("/t/280");

    assert.ok(
      exists(".event-label.deadline.past-due"),
      "the event-label is visible"
    );
    assert.strictEqual(
      query(".event-label .deadline").innerText.trim().split(":")[0],
      I18n.t("event_label.deadline.past_due"),
      "the event-label shows the Past Due element"
    );
  });
});
