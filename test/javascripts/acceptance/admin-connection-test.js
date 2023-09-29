import selectKit from "discourse/tests/helpers/select-kit-helper";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { visit, settled } from "@ember/test-helpers";
import { registerRoutes } from "../helpers/events-routes";

function sourceRoutes(needs) {
  needs.pretender((server, helper) => {
    server.get("/admin/events", () => {
      return helper.response({});
    });
    server.get("/admin/events/connection", () => {
      return helper.response({
        sources: [
          {
            id: 1,
            name: "my_source",
            provider_id: 1,
            source_options: {
              organization_id: "1234",
            },
          },
        ],
        connections: [
          {
            id: 1,
            user: {
              id: 1,
              username: "angus",
            },
            category_id: 2,
            source_id: 1,
            client: "events",
          },
        ],
        clients: ["events"],
      });
    });
    server.put("/admin/events/connection/new", () => {
      return helper.response({
        connection: {
          id: 1,
          user: {
            id: 1,
            username: "angus",
          },
          category_id: 2,
          source_id: 2,
          client: "events",
        },
      });
    });
    server.put("/admin/events/connection/:id", () => {
      return helper.response({
        connection: {
          id: 1,
          user: {
            id: 1,
            username: "angus",
          },
          category_id: 2,
          source_id: 3,
          client: "events",
        },
      });
    });
    server.delete("/admin/events/connection/:id", () => {
      return helper.response({ success: "OK" });
    });
    server.get("/u/search/users", () => {
      return helper.response({
        users: [
          {
            username: "angus",
            name: "Angus McLeod",
            avatar_template:
              "https://avatars.discourse.org/v3/letter/a/41988e/{size}.png",
          },
        ],
      });
    });
  });
}

acceptance("Events | Connection", function (needs) {
  needs.user({ username: "angus" });
  needs.settings({ events_enabled: true });

  registerRoutes(needs);
  sourceRoutes(needs);

  test("Displays the connection admin", async (assert) => {
    await visit("/admin/events/connection");

    assert.ok(exists(".events.connection"), "it shows the connection route");

    assert.equal(
      find(".admin-events-controls h2").eq(0).text().trim(),
      "Connections",
      "title displayed"
    );
  });

  test("Add connection works", async (assert) => {
    await visit("/admin/events/connection");

    await click("#add-connection");

    assert.ok(
      exists("tr[data-connection-id=new]"),
      "it displays a new connection row"
    );
    assert.ok(
      find("tr[data-connection-id=new] .save-connection").prop("disabled"),
      "it disables the save button"
    );

    const userSelect = selectKit("tr[data-connection-id=new] .connection-user");
    await userSelect.expand();
    await fillIn(".connection-user input.filter-input", "angus");
    await settled();
    await userSelect.selectRowByValue("angus");

    await selectKit("tr[data-connection-id=new] .connection-category").expand();
    await selectKit(
      "tr[data-connection-id=new] .connection-category"
    ).selectRowByValue(2);

    await selectKit("tr[data-connection-id=new] .connection-source").expand();
    await selectKit(
      "tr[data-connection-id=new] .connection-source"
    ).selectRowByValue(1);

    await selectKit("tr[data-connection-id=new] .connection-client").expand();
    await selectKit(
      "tr[data-connection-id=new] .connection-client"
    ).selectRowByValue("events");

    assert.ok(
      find("tr[data-connection-id=new] .save-connection").prop("disabled") ===
        false,
      "it enables the save button"
    );

    await click("tr[data-connection-id=new] .save-connection");
  });

  test("Edit connection works", async (assert) => {
    await visit("/admin/events/connection");

    await selectKit("tr[data-connection-id='1'] .connection-category").expand();
    await selectKit(
      "tr[data-connection-id='1'] .connection-category"
    ).selectRowByValue(1);

    assert.ok(
      find("tr[data-connection-id='1'] .save-connection").prop("disabled") ===
        false,
      "it enables the save button"
    );

    await click(".save-connection");
  });

  test("Filter modal works", async (assert) => {
    await visit("/admin/events/connection");

    await click("tr[data-connection-id='1'] .btn.show-filters");
    assert.ok(
      exists(".events-connection-filters-modal"),
      "it shows the filter modal"
    );

    await click(".events-connection-filters-modal .add-filter");
    assert.ok(
      exists(".events-connection-filters-modal .filter-column"),
      "it shows the filter column"
    );
    assert.ok(
      exists(".events-connection-filters-modal .filter-value"),
      "it shows the filter value"
    );

    await selectKit(".events-connection-filters-modal .filter-column").expand();
    await selectKit(
      ".events-connection-filters-modal .filter-column"
    ).selectRowByValue("name");

    await fillIn(
      ".events-connection-filters-modal .filter-value",
      "Event Name"
    );

    await click(".events-connection-filters-modal .btn-primary");

    assert.ok(
      exists("tr[data-connection-id='1'] .btn-primary.show-filters"),
      "the filter content is indicated by a btn-primary class"
    );

    await click("#add-connection");

    await click("tr[data-connection-id='new'] .btn.show-filters");
    assert.ok(
      exists(".events-connection-filters-modal"),
      "it shows the filter modal"
    );

    await click(".events-connection-filters-modal .add-filter");

    assert.blank(
      selectKit(".events-connection-filters-modal .filter-column")
        .header()
        .value(),
      "filter column is blank"
    );
    assert.blank(
      query(".events-connection-filters-modal .filter-value").value,
      "filter value is blank"
    );
  });
});
