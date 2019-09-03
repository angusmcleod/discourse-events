import DropdownSelectBoxComponent from "select-kit/components/dropdown-select-box";
import computed from 'ember-addons/ember-computed-decorators';

export default DropdownSelectBoxComponent.extend({
  classNames: ["events-calendar-subscription"],
  rowComponent: "events-calendar-subscription-row",
  filterComponent: "events-calendar-subscription-warning",

  @computed('authSuffix')
  content(authSuffix) {
    const baseUrl = window.location.host + window.location.pathname;
    const timeZone = moment.tz.guess();
    return [
      {
        id: `webcal://${baseUrl}.ics?time_zone=${timeZone}${authSuffix}`,
        name: I18n.t('events_calendar.ical')
      },
      {
        id: `${baseUrl}.rss?time_zone=${timeZone}${authSuffix}`,
        name: I18n.t('events_calendar.rss')
      }
    ];
  },

  @computed('userApiKey', 'siteSettings.login_required', 'category.read_restricted')
  authSuffix(userApiKey, loginRequired, privateCategory) {
    if (!loginRequired && !privateCategory) return "";
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

  actions: {
    onSelect() {}
  }
});
