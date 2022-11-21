# frozen_string_literal: true

module ListableTopicSerializerEventsExtension
  def include_excerpt?
    super || object.include_excerpt
  end
end
