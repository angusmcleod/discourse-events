# frozen_string_literal: true

module DiscourseEvents
  class PostEventSerializer < BasicEventSerializer
    attributes :admin_url,
               :can_manage

    def can_manage
      scope.can_manage_events?
    end

    def admin_url
      object.url.present? ? object.url : object.provider.url
    end

    def include_admin_url?
      scope.can_manage_events?
    end
  end
end
