import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import Category from "discourse/models/category";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";

function sourceRoutes(needs) {
  needs.pretender((server, helper) => {
    server.get("/admin/plugins/events", () => {
      return helper.response({});
    });
    server.get("/admin/plugins/events/connection", () => {
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
            client: "discourse_events",
            source_id: 1,
          },
        ],
        clients: ["discourse_events", "discourse_calendar"],
      });
    });
    server.put("/admin/plugins/events/connection/new", () => {
      return helper.response({
        connection: {
          id: 1,
          user: {
            id: 1,
            username: "angus",
          },
          category_id: 2,
          source_id: 2,
        },
      });
    });
    server.put("/admin/plugins/events/connection/:id", () => {
      return helper.response({
        connection: {
          id: 1,
          user: {
            id: 1,
            username: "angus",
          },
          category_id: 2,
          source_id: 3,
        },
      });
    });
    server.delete("/admin/plugins/events/connection/:id", () => {
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

  sourceRoutes(needs);

  test("Displays the connection admin", async (assert) => {
    await visit("/admin/plugins/events/connection");

    assert.ok(exists(".events.connection"), "it shows the connection route");

    assert.equal(
      query(".admin-events-controls h2").innerText.trim(),
      "Connections",
      "title displayed"
    );
  });

  test("Add connection works", async (assert) => {
    const category = Category.findById(2);
    category.set("events_enabled", true);

    await visit("/admin/plugins/events/connection");
    await click("#add-connection");

    assert.ok(
      exists("tr[data-connection-id=new]"),
      "it displays a new connection row"
    );
    assert.strictEqual(
      query("tr[data-connection-id=new] .save-connection").disabled,
      true,
      "it disables the save button"
    );

    const userSelect = selectKit("tr[data-connection-id=new] .connection-user");
    await userSelect.expand();
    await fillIn(".connection-user input.filter-input", "angus");

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
    ).selectRowByValue("discourse_events");

    assert.strictEqual(
      query("tr[data-connection-id=new] .save-connection").disabled,
      false,
      "it enables the save button"
    );

    await click("tr[data-connection-id=new] .save-connection");
  });

  test("Edit connection works", async (assert) => {
    const category = Category.findById(1);
    category.set("events_enabled", true);

    await visit("/admin/plugins/events/connection");

    await selectKit("tr[data-connection-id='1'] .connection-category").expand();
    await selectKit(
      "tr[data-connection-id='1'] .connection-category"
    ).selectRowByValue(1);

    assert.strictEqual(
      query("tr[data-connection-id='1'] .save-connection").disabled,
      false,
      "it enables the save button"
    );

    await click(".save-connection");
  });

  test("Filter modal works", async (assert) => {
    await visit("/admin/plugins/events/connection");

    await click("tr[data-connection-id='1'] .btn.show-filters");

    assert.ok(exists(".events-filters-modal"), "it shows the filter modal");

    await click(".events-filters-modal .add-filter");
    assert.ok(
      exists(".events-filters-modal .filter-column"),
      "it shows the filter column"
    );
    assert.ok(
      exists(".events-filters-modal .filter-value"),
      "it shows the filter value"
    );

    await selectKit(".events-filters-modal .filter-column").expand();
    await selectKit(".events-filters-modal .filter-column").selectRowByValue(
      "name"
    );

    await selectKit(".events-filters-modal .filter-operator").expand();
    await selectKit(".events-filters-modal .filter-operator").selectRowByValue(
      "like"
    );

    await fillIn(".events-filters-modal .filter-value", "Event Name");

    await click(".events-filters-modal .btn-primary");

    await click("#add-connection");

    await click("tr[data-connection-id='new'] .btn.show-filters");
    assert.ok(exists(".events-filters-modal"), "it shows the filter modal");

    await click(".events-filters-modal .add-filter");

    assert.blank(
      selectKit(".events-filters-modal .filter-column").header().value(),
      "filter column is blank"
    );
    assert.blank(
      selectKit(".events-filters-modal .filter-operator").header().value(),
      "filter operator is blank"
    );
    assert.blank(
      query(".events-filters-modal .filter-value").value,
      "filter value is blank"
    );
  });
});
