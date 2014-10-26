Rails.application.routes.draw do
  resources :subscriber_lists, path: "subscriber-lists", only: [:create]
  get "/subscriber-lists", to: "subscriber_lists#show"

  resources :notifications, only: [:create]
end
