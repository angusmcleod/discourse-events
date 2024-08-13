import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";

function sourceRoutes(needs) {
  needs.pretender((server, helper) => {
    server.get("/admin/events", () => {
      return helper.response({});
    });
    server.get("/admin/events/log", () => {
      return helper.response({
        logs: [
          {
            id: 1,
            level: "info",
            context: "import",
            message:
              "Finished importing from my_source. Retrieved 20 events, created 20 events and updated 0 events.",
            created_at: "2022-11-06T18:00:00.000Z",
          },
        ],
        page: 1,
      });
    });
    server.delete("/admin/events/log", () => {
      return helper.response({ success: "OK" });
    });
  });
}

acceptance("Events | log", function (needs) {
  needs.user();
  needs.settings({ events_enabled: true });

  sourceRoutes(needs);

  test("Displays the log admin", async (assert) => {
    await visit("/admin/events/log");

    assert.ok(exists(".events.log"), "it shows the log route");

    assert.equal(
      query(".admin-events-controls h2").innerText.trim(),
      "Logs",
      "title displayed"
    );

    assert.equal(
      query("td.log-level").innerText.trim(),
      "info",
      "Log level displayed"
    );
  });
});
