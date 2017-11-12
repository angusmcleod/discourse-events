class CalendarEvents::EventController < ApplicationController
  def category_list
    params.require(:category_id)
    params.permit(:period)

    opts = { category_id: params[:category_id] }

    opts[:period] = params[:period] if params.include?(:period)

    events = CalendarEvents::List.category(opts)

    render_serialized(events, CalendarEvents::EventSerializer)
  end
end
