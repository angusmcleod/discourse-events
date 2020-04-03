import DropdownSelectBoxComponent from "select-kit/components/dropdown-select-box";
import computed from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';

export default DropdownSelectBoxComponent.extend({
  classNames: ["events-calendar-subscription"],
  
  modifyComponentForRow() {
    return "events-calendar-subscription-row";
  },
  
  getDomain() {
    return location.hostname + (location.port ? ':' + location.port : '');
  },

  @computed('authParams')
  content(authParams) {
    const url = this.getDomain() + Discourse.getURL(`/c/${Category.slugFor(this.category)}`);
    const timeZone = moment.tz.guess();
    return [
      {
        id: `webcal://${url}/l/calendar.ics?time_zone=${timeZone}${authParams}`,
        name: I18n.t('events_calendar.ical')
      },
      {
        id: `${url}/l/calendar.rss?time_zone=${timeZone}${authParams}`,
        name: I18n.t('events_calendar.rss')
      }
    ];
  },

  @computed('userApiKey', 'showAuthParams')
  authParams(userApiKey, showAuthParams) {
    if (!showAuthParams) return "";
    if (!userApiKey) return "";
    let suffix = "";
    const {
      key,
      client_id,
    } = userApiKey;
    // only append if available
    if (key) {
      suffix += `&user_api_key=${encodeURIComponent(key)}`;
      if (client_id) {
        // be aware that the client_id be changed at will by the user
        suffix += `&user_api_client_id=${encodeURIComponent(client_id)}`;
      }
    }
    return suffix;
  },

  @computed('userApiKeys.[]')
  userApiKey(keys) {
    if (keys && Array.isArray(keys)) {
      return keys[0];
    }
  },

  @computed('siteSettings.login_required', 'category.read_restricted', 'siteSettings.events_webcal_always_add_user_api_key')
  showAuthParams(loginRequired, privateCategory, alwaysAddKeys) {
    return loginRequired || privateCategory || alwaysAddKeys;
  },

  @computed('userApiKey', 'showAuthParams')
  filterComponent(userApiKey, showAuthParams) {
    return (showAuthParams && userApiKey)
      ? "events-calendar-subscription-warning"
      : null;
  },

  actions: {
    onSelect() {}
  }
});
