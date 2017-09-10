export default {
  setupComponent(args, component) {
    Ember.run.scheduleOnce('afterRender', this, function() {
      if (args.model.get('showEventControls')) {
        $('.composer-controls-event').addClass('show-control');
      }
    })
  }
}
