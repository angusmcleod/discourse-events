# frozen_string_literal: true
module DiscourseEventsTopicExtension
  def reload(options = nil)
    @event = nil
    super(options)
  end

  def event
    @event ||= DiscourseEvents::Event.find_by(id: self.custom_fields['event_id'])
  end
end