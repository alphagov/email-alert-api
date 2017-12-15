Rails.application.routes.draw do
  defaults format: :json do
    resources :subscriber_lists, path: "subscriber-lists", only: %i[create]
    get "/subscriber-lists", to: "subscriber_lists#show"

    resources :notifications, only: %i[create index show]
    resources :status_updates, path: "status-updates", only: %i[create]
    resources :subscriptions, only: %i[create]
    get "subscribables/:gov_delivery_id", to: "subscribables#show"

    get "/healthcheck", to: "healthcheck#check"

    post "/unsubscribe/:uuid", to: "unsubscribe#unsubscribe"
  end
end
