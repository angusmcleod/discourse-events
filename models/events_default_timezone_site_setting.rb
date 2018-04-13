require_dependency 'enum_site_setting'

class EventsDefaultTimezoneSiteSetting < EnumSiteSetting
  def self.valid_value?(val)
    values.any? { |v| v[:value].to_s == val.to_s }
  end

  def self.values
    @values ||= ActiveSupport::TimeZone::MAPPING.map do |k, v|
      {
        name: ActiveSupport::TimeZone.new(k).to_s,
        value: v
      }
    end
  end
end
