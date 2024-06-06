export default {
  resource: "admin",
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
