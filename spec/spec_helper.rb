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
  config.include ActiveSupport::Testing::TimeHelpers

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  config.after type: :request do
    logout
  end
end

WebMock.disable_net_connect!(allow_localhost: true)

SidekiqUniqueJobs.config.enabled = false

Sidekiq::Testing.inline!
Sidekiq::Worker.clear_all
Sidekiq::Logging.logger = nil
