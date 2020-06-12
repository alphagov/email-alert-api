ENV["RAILS_ENV"] ||= "test"

$LOAD_PATH << File.join(__dir__, "..")

require "webmock/rspec"
require "base64"
require "config/environment"
require "rspec/rails"
require "govuk_sidekiq/testing"
require "gds-sso/lint/user_spec"
require "db/seeds"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }

Rails.application.load_tasks

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.use_transactional_fixtures = true
  config.include AuthenticationHelpers, type: :request
  config.include RequestHelpers, type: :request
  config.include FactoryBot::Syntax::Methods

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  config.after type: :request do
    logout
  end

  config.around(:each, testing_transactions: true) do |example|
    DatabaseCleaner.allow_remote_database_url = true
    self.use_transactional_tests = false
    DatabaseCleaner.strategy = :truncation
    example.run
    DatabaseCleaner.clean
    self.use_transactional_tests = true
  end
end

WebMock.disable_net_connect!(allow_localhost: true)

Sidekiq::Testing.inline!
Sidekiq::Worker.clear_all
Sidekiq::Logging.logger = nil
