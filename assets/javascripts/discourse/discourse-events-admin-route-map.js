export default {
  resource: "admin",
  map() {
    this.route("events", { path: "/events" }, function () {
      this.route("provider", { path: "/provider" });
      this.route("source", { path: "/source" });
      this.route("connection", { path: "/connection" });
      this.route("event", { path: "/event" });
      this.route("log", { path: "/log" });
    });
  },
};
