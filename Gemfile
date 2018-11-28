source 'https://rubygems.org'

gem 'pg', '~> 1.1'
gem 'rails', '~> 5.2'

gem 'activerecord-import', '~> 0.27'
gem 'bootsnap', require: false
gem 'with_advisory_lock', '~> 4.0'

gem 'aws-sdk-s3', '~> 1'
gem 'faraday', '0.15.4'
gem 'foreman', '~> 0.85'
gem 'gds-api-adapters', '~> 54.1'
gem 'gds-sso', '~> 13.6'
gem 'govuk_app_config', '~> 1.10'
# This is pinned < 2 until gds-sso supports JWT > 2
gem 'jwt', '~> 2.1'
gem 'nokogiri', '~> 1.8'
gem 'notifications-ruby-client', '~> 2.9'
gem 'plek', '~> 2.1'
gem 'redcarpet', '~> 3.4'

gem 'govuk_sidekiq', '~> 3.0'
gem 'ratelimit', '~> 1.0'
gem 'sidekiq-scheduler', '~> 3.0'

group :test do
  gem 'climate_control'
  gem 'equivalent-xml'
  gem 'factory_bot_rails'
  gem 'timecop'
  gem 'webmock'
end

group :development, :test do
  gem 'govuk-lint', '~> 3.9'
  gem 'listen', '3.1.5'
  gem 'pry-byebug'
  gem 'rspec-rails', '3.8.1'
  gem 'ruby-prof', '~> 0.17'
end
