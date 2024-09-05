# frozen_string_literal: true
module EventsGuardianExtension
  def can_edit_post?(post)
    return false if post.remote_events.present?
    super
  end
end
