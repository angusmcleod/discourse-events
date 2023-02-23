# frozen_string_literal: true

module DiscourseEvents
  class LogController < AdminController

    PAGE_LIMIT = 30

    def index
      page = params[:page].to_i
      order = params[:order] || "created_at"
      direction = ActiveRecord::Type::Boolean.new.cast(params[:asc]) ? "ASC" : "DESC"
      offset = page * PAGE_LIMIT

      logs = Log.order("#{order} #{direction}")
        .offset(offset)
        .limit(PAGE_LIMIT)

      render_json_dump(
        page: page,
        logs: serialize_data(logs, LogSerializer, root: false)
      )
    end
  end
end
