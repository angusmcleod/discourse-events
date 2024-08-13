import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";

function providerRoutes(needs) {
  needs.pretender((server, helper) => {
    server.get("/admin/events", () => {
      return helper.response({});
    });
    server.get("/admin/events/provider", () => {
      return helper.response({
        providers: [
          {
            id: 1,
            name: "my_provider",
          },
        ],
      });
    });
    server.put("/admin/events/provider/new", () => {
      return helper.response({
        provider: {
          id: 2,
          name: "my_new_provider",
          provider_type: "developer",
          authenticated: true,
        },
      });
    });
    server.put("/admin/events/provider/:id", () => {
      return helper.response({
        provider: {
          id: 1,
          name: "my_updated_provider",
          provider_type: "developer",
          authenticated: true,
        },
      });
    });
    server.delete("/admin/events/provider/:id", () => {
      return helper.response({ success: "OK" });
    });
  });
}

acceptance("Events | Provider", function (needs) {
  needs.user();
  needs.settings({ events_enabled: true });

  providerRoutes(needs);

  test("Displays the provider admin", async (assert) => {
    await visit("/admin/events/provider");

    assert.ok(exists(".events.provider"), "it shows the provider route");

    assert.equal(
      query(".admin-events-controls h2").innerText.trim(),
      "Providers",
      "title displayed"
    );
  });

  test("Add provider works", async (assert) => {
    await visit("/admin/events/provider");

    await click("#add-provider");

    assert.ok(
      exists("tr[data-provider-id=new]"),
      "it displays a new provider row"
    );
    assert.strictEqual(
      query("tr[data-provider-id=new] .save-provider").disabled,
      true,
      "it disables the save button"
    );

    await fillIn("tr[data-provider-id=new] .provider-name", "my_provider");

    assert.strictEqual(
      query("tr[data-provider-id=new] .save-provider").disabled,
      false,
      "it enabled the save button"
    );

    await click("tr[data-provider-id=new] .save-provider");
  });

  test("Edit provider works", async (assert) => {
    await visit("/admin/events/provider");

    await fillIn(
      "tr[data-provider-id='1'] .provider-name",
      "my_updated_provider"
    );

    assert.strictEqual(
      query("tr[data-provider-id='1'] .save-provider").disabled,
      false,
      "it enabled the save button"
    );

    await click(".save-provider");
  });

  test("Appropriate credential controls show for different provider types", async (assert) => {
    await visit("/admin/events/provider");

    assert.equal(
      query(".credentials-container").innerText.trim(),
      "No Credentials",
      "no credentials displayed"
    );

    await selectKit(".provider-type").expand();
    await selectKit(".provider-type").selectRowByValue("icalendar");

    assert.equal(
      query("tr[data-provider-id='1'] .credentials-container").innerText.trim(),
      "No Credentials",
      "no credentials displayed"
    );

    await selectKit(".provider-type").expand();
    await selectKit(".provider-type").selectRowByValue("eventbrite");

    assert.ok(exists("input.token"), "it displays the token input");
    assert.ok(
      exists(".btn.toggle-secret-visibility"),
      "it displays the secret visibility toggle"
    );
  });
});
