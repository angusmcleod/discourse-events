# frozen_string_literal: true
module DiscoursePostEventSerializerExtension
  def custom_fields
    _custom_fields = super
    _custom_fields[:video_url] = event_record&.video_url if event_record&.video_url
    _custom_fields
  end

  def event_record
    @event_record ||= object.post&.topic&.event_record
  end
end
