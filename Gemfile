source "https://rubygems.org"

gem "rails", "7.0.4"

gem "bootsnap", require: false
gem "faraday"
gem "gds-api-adapters"
gem "gds-sso"
gem "govuk_app_config"
gem "govuk_document_types"
gem "govuk_personalisation"
gem "govuk_sidekiq"
gem "json-schema"
gem "jwt"
gem "mail", "~> 2.7.1"  # TODO: remove once https://github.com/mikel/mail/issues/1489 is fixed.
gem "nokogiri"
gem "notifications-ruby-client"
gem "pg"
gem "plek"
gem "ratelimit"
gem "redcarpet"
gem "sentry-sidekiq"
gem "sidekiq-scheduler"
gem "with_advisory_lock"

group :test do
  gem "climate_control"
  gem "equivalent-xml"
  gem "factory_bot_rails"
  gem "webmock"
end

group :development, :test do
  gem "database_cleaner"
  gem "listen"
  gem "pact", require: false
  gem "pact_broker-client"
  gem "pry-byebug"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
  gem "simplecov"
end
