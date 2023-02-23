# frozen_string_literal: true
module EventsGuardianExtension
  def can_edit_post?(post)
    return false if post.event_connection.present?
    super
  end
end
