import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { visit } from "@ember/test-helpers";

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
      find(".admin-events-controls h2").eq(0).text().trim(),
      "Logs",
      "title displayed"
    );

    assert.equal(
      find("td.log-level").eq(0).text().trim(),
      "info",
      "Log level displayed"
    );
  });
});
