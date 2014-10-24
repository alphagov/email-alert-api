Rails.application.routes.draw do
  resources :subscriber_lists, path: "subscriber-lists", only: [:create]
end
