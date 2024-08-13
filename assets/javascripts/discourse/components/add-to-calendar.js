import Component from "@ember/component";
import { bind } from "@ember/runloop";
import $ from "jquery";
import { default as discourseComputed } from "discourse-common/utils/decorators";
import { googleUri, icsUri } from "../lib/date-utilities";

export default Component.extend({
  expanded: false,
  classNames: "add-to-calendar",

  didInsertElement() {
    this._super(...arguments);
    $(document).on("click", bind(this, this.outsideClick));
  },

  willDestroyElement() {
    this._super(...arguments);
    $(document).off("click", bind(this, this.outsideClick));
  },

  outsideClick(e) {
    if (!this.isDestroying && !$(e.target).closest(".add-to-calendar").length) {
      this.set("expanded", false);
    }
  },

  @discourseComputed("topic.event")
  calendarUris() {
    const topic = this.get("topic");

    let params = {
      event: topic.event,
      title: topic.title,
      url: window.location.hostname + topic.get("url"),
    };

    if (topic.location && topic.location.geo_location) {
      params["location"] = topic.location.geo_location.address;
    }

    return [
      { uri: googleUri(params), label: "google" },
      { uri: icsUri(params), label: "ics" },
    ];
  },

  actions: {
    expand() {
      this.toggleProperty("expanded");
    },
  },
});
