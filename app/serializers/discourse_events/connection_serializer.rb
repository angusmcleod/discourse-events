# frozen_string_literal: true

module DiscourseEvents
  class ConnectionSerializer < ApplicationSerializer
    attributes :id, :user, :category_id, :source_id

    has_many :filters, serializer: FilterSerializer, embed: :objects

    def user
      ConnectionUserSerializer.new(object.user, root: false).as_json
    end
  end
end
