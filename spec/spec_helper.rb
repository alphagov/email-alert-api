ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails"

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

ActiveRecord::Migration.maintain_test_schema!

email_alert_api_sql_file = Tempfile.new("email-alert-api.sql")
email_alert_api_sql_file.write(URI.parse("https://raw.githubusercontent.com/alphagov/govuk-helm-charts/main/charts/db-backup/scripts/email-alert-api.sql").open(&:read))
email_alert_api_sql_file.close

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.use_transactional_fixtures = true
  config.include AuthenticationHelpers, type: :request
  config.include RequestHelpers, type: :request
  config.include NotifyRequestHelpers, type: :request
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  config.after type: :request do
    logout
  end

  # configuring sending all emails to Notify for request tests
  config.around type: :request do |example|
    ClimateControl.modify(GOVUK_NOTIFY_RECIPIENTS: "*") do
      stub_notify
      example.run
    end
  end

  config.add_setting :email_alert_api_sql_file_path
  config.email_alert_api_sql_file_path = email_alert_api_sql_file.path
end

WebMock.disable_net_connect!(allow_localhost: true)

Sidekiq::Testing.inline!
Sidekiq::Worker.clear_all
Sidekiq.configure_client do |config|
  config.logger = nil
end
