import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import discoveryFixtures from "discourse/tests/fixtures/discovery-fixtures";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import { cloneJSON } from "discourse-common/lib/object";
import { default as Timezones } from "../fixtures/timezone-fixtures";

const setupServer = (needs, attrs = {}) => {
  needs.pretender((server, helper) => {
    server.get("/c/dev/7/l/latest.json", () => {
      const json = cloneJSON(discoveryFixtures["/c/dev/7/l/latest.json"]);
      if (attrs.event) {
        json.topic_list.topics[0].event = attrs.event;
      }
      return helper.response(json);
    });
  });
};

acceptance("Events | topic list without an event", function (needs) {
  needs.user();
  needs.site({"event_timezones": Timezones['event_timezones']});
  setupServer(needs);

  test("does not show event", async function (assert) {
    await visit("/c/dev");

    assert.ok(
      !exists(".event-link"),
      "the event-link is not visible"
    );
  });
});

acceptance("Events | topic list with an event", function (needs) {
  needs.user();
  needs.site({"event_timezones": Timezones['event_timezones']});
  setupServer(needs, {
    event: {
      start: "2022-11-06T12:00:00.000Z",
      timezone: "Australia/Perth"
    }
  });

  test("shows event", async function (assert) {
    await visit("/c/dev");

    assert.ok(
      exists(".event-link"),
      "the event-link is visible"
    );
    assert.strictEqual(
      query(".event-link .date").innerText.trim(),
      "11-6, 20:00, (GMT+08:00) Perth",
      "the event-label shows the right datetime"
    );
  });
});