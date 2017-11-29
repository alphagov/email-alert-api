Rails.application.routes.draw do
  resources :subscriber_lists, path: "subscriber-lists", only: [:create]
  get "/subscriber-lists", to: "subscriber_lists#show"

  resources :notifications, only: %i[create index show]
  resources :status_updates, path: "status-updates", only: %i[create]

  get "/healthcheck", to: "healthcheck#check"

  post "/unsubscribe/:uuid", to: "unsubscribe#unsubscribe"
end
