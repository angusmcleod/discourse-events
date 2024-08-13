import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import topicFixtures from "discourse/tests/fixtures/topic";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import { cloneJSON } from "discourse-common/lib/object";
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
  needs.site({"event_timezones": Timezones['event_timezones']});
  setupServer(needs);

  test("does not show event", async function (assert) {
    await visit("/t/280");

    assert.ok(
      !exists(".event-label"),
      "the event-label is not visible"
    );
  });
});

acceptance("Events | topic with an event", function (needs) {
  needs.user();
  needs.site({"event_timezones": Timezones['event_timezones']});
  setupServer(needs, {
    event: {
      start: "2022-11-06T12:00:00.000Z",
      timezone: "Australia/Perth"
    }
  });

  test("shows event", async function (assert) {
    await visit("/t/280");

    assert.ok(
      exists(".event-label"),
      "the event-label is visible"
    );
    assert.strictEqual(
      query(".event-label .date").innerText.trim(),
      "November 6th, 20:00, (GMT+08:00) Perth",
      "the event-label shows the right datetime"
    );
  });
});