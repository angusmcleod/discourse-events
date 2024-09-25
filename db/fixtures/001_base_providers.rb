# frozen_string_literal: true
%w[icalendar outlook google].each do |provider|
  DiscourseEvents::Provider.find_or_create_by(provider_type: provider)
end
