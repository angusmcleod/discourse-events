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
    server.get("/admin/events/event", () => {
      return helper.response({
        events: [
          {
            id: 1,
            start_time: "2022-11-06T18:00:00.000Z",
            end_time: "2022-11-06T21:00:00.000Z",
            name: "La Traviata",
            description:
              "An opera in three acts by Giuseppe Verdi set to an Italian libretto by Francesco Maria Piave.",
            status: "draft",
            url: "https://event-platfom.com/events/la-traviata",
            created_at: "2022-09-28T14:38:03.711Z",
            updated_at: "2022-09-28T14:38:03.711Z",
            topics: [
              {
                id: 1,
                title: "Event Topic",
                fancy_title: "Event Topic",
              },
            ],
            source: {
              id: 1,
              name: "my_source",
              provider_id: 1,
            },
          },
        ],
        page: 1,
      });
    });
    server.delete("/admin/events/event", () => {
      return helper.response({ success: "OK" });
    });
  });
}

acceptance("Events | Event", function (needs) {
  needs.user();
  needs.settings({ events_enabled: true });

  sourceRoutes(needs);

  test("Displays the event admin", async (assert) => {
    await visit("/admin/events/event");

    assert.ok(exists(".events.event"), "it shows the event route");

    assert.equal(
      query(".admin-events-controls h2").innerText.trim(),
      "Events",
      "title displayed"
    );

    assert.equal(
      query(".events-event-row .name").innerText.trim(),
      "La Traviata",
      "Name displayed"
    );
  });
});
