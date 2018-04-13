require_dependency 'enum_site_setting'

class EventsDefaultTimezoneSiteSetting < EnumSiteSetting
  def self.valid_value?(val)
    values.any? { |v| v[:value].to_s == val.to_s }
  end

  def self.values
    @values ||= self.timezones.map do |k, v|
      {
        name: ActiveSupport::TimeZone.new(k).to_s,
        value: v
      }
    end
  end

  def self.timezones
    timezones = ActiveSupport::TimeZone::MAPPING
    zone_map = []
    remove_zones = []

    # Remove the duplicate zones where the label doesn't include the city in the zone.
    timezones.each do |k, v|
      if zone_map.include?(v)
        duplicates = timezones.select { |key, val| val === v }
        remove = duplicates.select{ |key, val| !val.include?(key) }
        remove_zones.push(*remove.keys)
      end

      zone_map.push(v)
    end

    timezones.except!(*remove_zones)
  end
end
