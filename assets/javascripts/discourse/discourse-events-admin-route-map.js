export default {
  resource: "admin.adminPlugins",
  path: "/plugins",
  map() {
    this.route("events", function () {
      this.route("event", function () {
        this.route("connection");
      });
      this.route("source");
      this.route("provider");
      this.route("log");
    });
  },
};
