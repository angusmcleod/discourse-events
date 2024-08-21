# frozen_string_literal: true
require_dependency "enum_site_setting"

class DiscourseEventsClientSiteSetting < EnumSiteSetting
  def self.valid_value?(val)
    return false unless DiscourseEvents::Connection.available_clients.include?(val.to_s)
    if val == 'discourse_events'
      SiteSetting.calendar_enabled && SiteSetting.discourse_post_event_enabled
    else
      true
    end
  end

  def self.values
    @values ||=
      DiscourseEvents::Connection.client_names.map do |v|
        { name: I18n.t("events.event.client.#{v}"), value: v }
      end
  end
end
