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

  @computed('userApiKey', 'category', 'siteSettings.login_required')
  authSuffix(userApiKey, category, loginRequired) {
    // only private sites need login
    if (!loginRequired) return "";
    // only append for private categories
    if (!category || !category.read_restricted) return "";
    const {
      key,
      client_id,
    } = userApiKey;
    // only append if available
    if (!key || !client_id) return "";
    return `&user_api_key=${key}&user_api_client_id=${client_id}`;
  },

  @computed('userApiKeys.[]')
  userApiKey(keys) {
    if (!keys || !Array.isArray(keys) || !keys.length) {
      return {};
    }
    return keys[0];
  },

  actions: {
    onSelect() {}
  }
});
