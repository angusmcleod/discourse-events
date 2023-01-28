import Site from "discourse/models/site";

function registerRoutes(needs) {
  needs.hooks.beforeEach(function() {
    Site.currentProp("filters").addObject("calendar");
  });
}

export {
  registerRoutes
}