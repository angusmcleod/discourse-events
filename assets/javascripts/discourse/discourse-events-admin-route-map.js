export default {
  resource: "admin.adminPlugins",
  path: "/plugins",
  map() {
    this.route("events", function () {
      this.route("provider");
      this.route("source");
      this.route("connection");
      this.route("event");
      this.route("log");
    });
  },
};
