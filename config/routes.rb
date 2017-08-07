Rails.application.routes.draw do
  resources :notification_logs, only: [:create]
  resources :subscriber_lists, path: "subscriber-lists", only: [:create]
  get "/subscriber-lists", to: "subscriber_lists#show"
  get "/topic-matches", to: "topic_matches#show"

  resources :notifications, only: [:create, :index, :show]

  get "/healthcheck", to: "healthcheck#check"
end
