require_dependency 'enum_site_setting'

class EventsTimezoneDisplaySiteSetting < EnumSiteSetting
  def self.valid_value?(val)
    values.any? { |v| v[:value].to_s == val.to_s }
  end

  def self.values
    @values ||= ['default', 'event', 'different'].map do |v|
      {
        name: I18n.t("site_settings.events_timezone_display_#{v}"),
        value: v
      }
    end
  end
end
