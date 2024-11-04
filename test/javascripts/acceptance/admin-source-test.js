import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { default as Subscriptions } from "../fixtures/subscription-fixtures";
import { default as Suppliers } from "../fixtures/supplier-fixtures";

function sourceRoutes(needs) {
  needs.pretender((server, helper) => {
    server.get("/admin/plugins/events/subscription", () => {
      return helper.response(Subscriptions["business"]);
    });
    server.get("/admin/plugins/subscription-client/suppliers", () => {
      return helper.response(Suppliers["authorized"]);
    });
    server.get("/admin/plugins/events", () => {
      return helper.response({});
    });
    server.get("/admin/plugins/events/source", () => {
      return helper.response({
        providers: [
          {
            id: 1,
            name: "my_provider",
            provider_type: "google",
            authenticated: true,
          },
          {
            id: 2,
            name: "my_other_provider",
            provider_type: "outlook",
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
              user_id: "1234",
              calendar_id: "1234",
            },
          },
        ],
        import_periods: {
          "5_minutes": 300,
          "30_minutes": 1800,
          "1_hour": 3600,
          "1_day": 86_400,
          "1_week": 604_800,
        },
        source_options: {
          icalendar: [
            {
              name: "uri",
              type: "text",
              default: "",
            },
          ],
          eventbrite: [
            {
              name: "organization_id",
              type: "number",
              default: null,
            },
          ],
          humanitix: [],
          eventzilla: [],
          meetup: [
            {
              name: "group_urlname",
              type: "text",
              default: "",
            },
          ],
          outlook: [
            {
              name: "user_id",
              type: "text",
              defualt: "",
            },
            {
              name: "calendar_id",
              type: "text",
              default: "",
            },
          ],
          google: [
            {
              name: "calendar_id",
              type: "text",
              default: "",
            },
          ],
        },
      });
    });
    server.put("/admin/plugins/events/source/new", () => {
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
    server.put("/admin/plugins/events/source/:id", () => {
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
    server.delete("/admin/plugins/events/source/:id", () => {
      return helper.response({ success: "OK" });
    });
  });
}

acceptance("Events | Source", function (needs) {
  needs.user();
  needs.settings({ events_enabled: true });

  sourceRoutes(needs);

  test("Displays the source admin", async (assert) => {
    await visit("/admin/plugins/events/source");

    assert.ok(exists(".events.source"), "it shows the source route");

    assert.equal(
      query(".admin-events-controls h2").innerText.trim(),
      "Sources",
      "title displayed"
    );
  });

  test("Add source works", async (assert) => {
    await visit("/admin/plugins/events/source");

    await click("#add-source");

    assert.ok(exists("tr[data-source-id=new]"), "it displays a new source row");
    assert.strictEqual(
      query("tr[data-source-id=new] .save-source").disabled,
      true,
      "it disables the save button"
    );

    await selectKit("tr[data-source-id=new] .source-provider").expand();
    await selectKit("tr[data-source-id=new] .source-provider").selectRowByValue(
      "google"
    );

    await fillIn("input[name=calendar_id]", "1234");

    assert.strictEqual(
      query("tr[data-source-id=new] .save-source").disabled,
      false,
      "it enables the save button"
    );

    await click("tr[data-source-id=new] .save-source");
  });

  test("Edit source works", async (assert) => {
    await visit("/admin/plugins/events/source");

    await selectKit("tr[data-source-id='1'] .source-provider").expand();
    await selectKit("tr[data-source-id='1'] .source-provider").selectRowByValue(
      "outlook"
    );

    assert.strictEqual(
      query("tr[data-source-id='1'] .save-source").disabled,
      false,
      "it enables the save button"
    );

    await click(".save-source");
  });

  test("Appropriate options show for source providers", async (assert) => {
    await visit("/admin/plugins/events/source");

    await selectKit(".source-provider").expand();
    await selectKit(".source-provider").selectRowByValue("outlook");

    assert.ok(
      exists("[name=calendar_id]"),
      "it displays the appropriate option"
    );
  });
});
