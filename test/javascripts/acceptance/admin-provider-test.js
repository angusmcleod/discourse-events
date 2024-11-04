import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import { default as Subscriptions } from "../fixtures/subscription-fixtures";
import { default as Suppliers } from "../fixtures/supplier-fixtures";

function providerRoutes(needs) {
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
    server.get("/admin/plugins/events/provider", () => {
      return helper.response({
        providers: [
          {
            id: 1,
            name: "my_provider",
            provider_type: "icalendar",
          },
          {
            id: 2,
            name: "my_google_provider",
            provider_type: "google",
          },
          {
            id: 3,
            name: "my_outlook_provider",
            provider_type: "outlook",
          },
        ],
      });
    });
    server.put("/admin/plugins/events/provider/new", () => {
      return helper.response({
        provider: {
          id: 2,
          name: "my_new_provider",
          provider_type: "developer",
          authenticated: true,
        },
      });
    });
    server.put("/admin/plugins/events/provider/:id", () => {
      return helper.response({
        provider: {
          id: 1,
          name: "my_updated_provider",
          provider_type: "developer",
          authenticated: true,
        },
      });
    });
    server.delete("/admin/plugins/events/provider/:id", () => {
      return helper.response({ success: "OK" });
    });
  });
}

acceptance("Events | Provider", function (needs) {
  needs.user();
  needs.settings({ events_enabled: true });

  providerRoutes(needs);

  test("Displays the provider admin", async (assert) => {
    await visit("/admin/plugins/events/provider");

    assert.ok(exists(".events.provider"), "it shows the provider route");

    assert.equal(
      query(".admin-events-controls h2").innerText.trim(),
      "Providers",
      "title displayed"
    );
  });

  test("Appropriate credential controls show for different provider types", async (assert) => {
    await visit("/admin/plugins/events/provider");

    assert.equal(
      query(
        "tr[data-provider-id='1'] .events-provider-authentication"
      ).innerText.trim(),
      "No Authentication",
      "no credentials displayed"
    );

    assert.ok(
      exists(".events-provider-credentials input.client-id"),
      "it displays the client id input"
    );
    assert.ok(
      exists(".events-provider-credentials .btn.toggle-secret-visibility"),
      "it displays the secret visibility toggle"
    );
  });
});
