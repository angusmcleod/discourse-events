# frozen_string_literal: true

DiscourseEvents::Engine.routes.draw do
  post "/rsvp/add" => "rsvp#add"
  post "/rsvp/remove" => "rsvp#remove"
  get "/api-keys" => "api_keys#index"
  get "/rsvp/users" => "rsvp#users"
end

Discourse::Application.routes.prepend do
  get "calendar.ics" => "list#calendar_ics", :format => :ics, :protocol => :webcal
  get "calendar.rss" => "list#calendar_feed", :format => :rss
  get "agenda.rss" => "list#agenda_feed", :format => :rss

  %w[users u].each do |root_path|
    get "#{root_path}/:username/preferences/webcal-keys" => "users#preferences",
        :constraints => {
          username: RouteFormat.username,
        }
  end

  get "c/*category_slug_path_with_id/l/calendar.ics" => "list#calendar_ics",
      :format => :ics,
      :protocol => :webcal
  get "c/*category_slug_path_with_id/l/calendar.rss" => "list#calendar_feed", :format => :rss
  get "c/*category_slug_path_with_id/l/agenda.rss" => "list#agenda_feed", :format => :rss

  mount ::DiscourseEvents::Engine, at: "/discourse-events"

  scope module: "discourse_events", constraints: AdminConstraint.new do
    get "/admin/events" => "admin#index"
    get "/admin/events/provider" => "provider#index"
    put "/admin/events/provider/new" => "provider#create"
    put "/admin/events/provider/:id" => "provider#update"
    get "/admin/events/provider/:id/authorize" => "provider#authorize"
    get "/admin/events/provider/:id/redirect" => "provider#redirect"
    delete "/admin/events/provider/:id" => "provider#destroy"
    get "/admin/events/source" => "source#index"
    put "/admin/events/source/new" => "source#create"
    put "/admin/events/source/:id" => "source#update"
    post "/admin/events/source/:id" => "source#import"
    delete "/admin/events/source/:id" => "source#destroy"
    get "/admin/events/connection" => "connection#index"
    put "/admin/events/connection/new" => "connection#create"
    put "/admin/events/connection/:id" => "connection#update"
    post "/admin/events/connection/:id" => "connection#sync"
    delete "/admin/events/connection/:id" => "connection#destroy"
    get "/admin/events/event" => "event#index"
    delete "/admin/events/event" => "event#destroy"
    get "/admin/events/log" => "log#index"
  end
end
