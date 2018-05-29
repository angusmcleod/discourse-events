import { getOwner } from 'discourse-common/lib/get-owner';

export default {
  setupComponent(attrs, component) {
    const controller = getOwner(this).lookup('controller:composer');
    component.set('eventValidation', controller.get('eventValidation'));
    controller.addObserver('eventValidation', () => {
      if (this._state === 'destroying') return;
      component.set('eventValidation', controller.get('eventValidation'));
    })
  }
}
