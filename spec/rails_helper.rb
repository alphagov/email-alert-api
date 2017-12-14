ENV["RAILS_ENV"] ||= "test"

$LOAD_PATH << File.join(__dir__, "..")

require "webmock/rspec"
require "base64"
require "config/environment"
require "rspec/rails"
require "govuk_sidekiq/testing"
require "gds-sso/lint/user_spec"
require "db/seeds"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.use_transactional_fixtures = true
  config.include FactoryGirl::Syntax::Methods
end

WebMock.disable_net_connect!(allow_localhost: true)

Sidekiq::Testing.inline!
Sidekiq::Worker.clear_all

JSON_HEADERS = {
  "CONTENT_TYPE" => "application/json",
  "ACCEPT" => "application/json",
  "HTTP_GOVUK_REQUEST_ID" => "request-id",
}.freeze

def login_as(user)
  GDS::SSO.test_user = user
end
