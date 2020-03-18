export default Ember.Controller.extend({
 
  actions: {
    hideModal(){
      this.get('model.update')(this.model.event);
      this.send('closeModal');
    }
  }
});
