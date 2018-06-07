require_dependency 'enum_site_setting'

class EventsTimezoneDefaultSiteSetting < EnumSiteSetting
  def self.valid_value?(val)
    return true if val == ""
    values.any? { |v| v[:value].to_s == val.to_s }
  end

  def self.values
    @values ||= self.timezones.map do |k, v|
      {
        name: "(GMT#{Time.now.in_time_zone(v).formatted_offset}) #{k}",
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
