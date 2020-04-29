import RestrictedUserRoute from "discourse/routes/restricted-user";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { getOwner } from "@ember/application";


export default RestrictedUserRoute.extend({
  showFooter: true,
  apiKey: null,

})