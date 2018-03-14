Rails.application.routes.draw do
  scope format: false, defaults: { format: :json } do
    root "welcome#index"
    resources :subscriber_lists, path: "subscriber-lists", only: %i[create]
    get "/subscriber-lists", to: "subscriber_lists#show"
    get "/subscribables/:slug", to: "subscribables#show"

    resources :notifications, only: %i[create index show]
    resources :status_updates, path: "status-updates", only: %i[create]
    resources :subscriptions, only: %i[create]

    get "/healthcheck", to: "healthcheck#check"

    post "/unsubscribe/:id", to: "unsubscribe#unsubscribe"
  end
end
