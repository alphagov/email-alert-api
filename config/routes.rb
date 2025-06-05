Rails.application.routes.draw do
  scope format: false, defaults: { format: :json } do
    resources :subscriber_lists, path: "subscriber-lists", only: %i[create]
    get "/subscriber-lists", to: "subscriber_lists#index"
    get "/subscriber-lists/:slug", to: "subscriber_lists#show"
    patch "/subscriber-lists/:slug", to: "subscriber_lists#update"
    post "/subscriber-lists/:slug/bulk-unsubscribe", to: "subscriber_lists#bulk_unsubscribe"
    get "/subscriber-lists/metrics/*path", to: "subscriber_lists#metrics"

    resources :content_changes, only: %i[create], path: "content-changes"
    resources :spam_reports, path: "spam-reports", only: %i[create]
    resources :status_updates, path: "status-updates", only: %i[create]
    resources :subscriptions, only: %i[create show update]

    get "/subscriptions/:id/latest", to: "subscriptions#latest_matching"

    patch "/subscribers/:id", to: "subscribers#change_address"
    delete "/subscribers/:id", to: "unsubscribe#unsubscribe_all"
    get "/subscribers/:id/subscriptions", to: "subscribers#subscriptions"

    post "/subscribers/auth-token", to: "subscribers_auth_token#auth_token"
    post "/subscriptions/auth-token", to: "subscriptions_auth_token#auth_token"

    get  "/subscribers/govuk-account/:govuk_account_id", to: "subscribers_govuk_account#show"
    post "/subscribers/govuk-account", to: "subscribers_govuk_account#authenticate"
    post "/subscribers/govuk-account/link", to: "subscribers_govuk_account#link_subscriber_to_account"

    post "/unsubscribe/:id", to: "unsubscribe#unsubscribe"

    get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
    get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
      GovukHealthcheck::SidekiqRedis,
      GovukHealthcheck::ActiveRecord,
    )
  end

  require "sidekiq/web"
  mount Sidekiq::Web, at: "/sidekiq"
end
