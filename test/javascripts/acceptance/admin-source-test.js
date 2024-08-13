import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";

function sourceRoutes(needs) {
  needs.pretender((server, helper) => {
    server.get("/admin/events", () => {
      return helper.response({});
    });
    server.get("/admin/events/source", () => {
      return helper.response({
        providers: [
          {
            id: 1,
            name: "my_provider",
            provider_type: "eventbrite",
            authenticated: true,
          },
        ],
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
      });
    });
    server.put("/admin/events/source/new", () => {
      return helper.response({
        source: {
          id: 2,
          name: "my_new_source",
          provider_id: 1,
          source_options: {
            organization_id: "1234",
          },
        },
      });
    });
    server.put("/admin/events/source/:id", () => {
      return helper.response({
        source: {
          id: 1,
          name: "my_updated_source",
          provider_id: 1,
          source_options: {
            organization_id: "1234",
          },
        },
      });
    });
    server.delete("/admin/events/source/:id", () => {
      return helper.response({ success: "OK" });
    });
  });
}

acceptance("Events | Source", function (needs) {
  needs.user();
  needs.settings({ events_enabled: true });

  sourceRoutes(needs);

  test("Displays the source admin", async (assert) => {
    await visit("/admin/events/source");

    assert.ok(exists(".events.source"), "it shows the source route");

    assert.equal(
      query(".admin-events-controls h2").innerText.trim(),
      "Sources",
      "title displayed"
    );
  });

  test("Add source works", async (assert) => {
    await visit("/admin/events/source");

    await click("#add-source");

    assert.ok(exists("tr[data-source-id=new]"), "it displays a new source row");
    assert.strictEqual(
      query("tr[data-source-id=new] .save-source").disabled,
      true,
      "it disables the save button"
    );

    await fillIn("tr[data-source-id=new] .source-name", "my_updated_source");

    await selectKit("tr[data-source-id=new] .source-provider").expand();
    await selectKit("tr[data-source-id=new] .source-provider").selectRowByValue(
      1
    );

    assert.strictEqual(
      query("tr[data-source-id=new] .save-source").disabled,
      false,
      "it enables the save button"
    );

    await click("tr[data-source-id=new] .save-source");
  });

  test("Edit source works", async (assert) => {
    await visit("/admin/events/source");

    await fillIn("tr[data-source-id='1'] .source-name", "my_updated_source");

    assert.strictEqual(
      query("tr[data-source-id='1'] .save-source").disabled,
      false,
      "it enables the save button"
    );

    await click(".save-source");
  });

  test("Appropriate options show for source providers", async (assert) => {
    await visit("/admin/events/source");

    await selectKit(".source-provider").expand();
    await selectKit(".source-provider").selectRowByValue(1);

    assert.ok(
      exists("[name=organization_id]"),
      "it displays the appropriate option"
    );
  });
});
