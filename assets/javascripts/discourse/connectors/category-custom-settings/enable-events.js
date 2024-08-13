export default {
  shouldRender(_, ctx) {
    return ctx.siteSettings.events_enabled;
  },
};
