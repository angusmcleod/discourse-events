function registerRoutes(needs) {
  needs.site({
    filters: ["latest", "unread", "new", "top", "calendar"],
  });
}

export { registerRoutes };
