class CalendarEvents::EventSerializer < ApplicationSerializer
  attributes :title, :start, :end, :url

  def start
    Time.at(object.custom_fields['event_start']).iso8601
  end

  def end
    Time.at(object.custom_fields['event_end']).iso8601
  end
end
