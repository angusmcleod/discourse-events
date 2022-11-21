import Component from "@ember/component";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

const KEY_ENDPOINT = "/discourse-events/api-keys.json";

export default Component.extend({
  actions: {
    show() {
      ajax(KEY_ENDPOINT, {
        type: "GET",
      })
        .then((result) => {
          this.set("apiKey", result["api_keys"][0]["key"]);
          this.set("clientID", result["api_keys"][0]["client_id"]);
        })
        .catch(popupAjaxError);
    },
  },
});
