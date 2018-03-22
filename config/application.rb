require_relative 'boot'

require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "gds_api/content_store"
require "notifications/client"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EmailAlertAPI
  class Application < Rails::Application
    config.api_only = true
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.eager_load_paths << Rails.root.join('lib')

    unless Rails.application.secrets.email_alert_auth_token
      raise "Email Alert Auth Token is not configured. See config/secrets.yml"
    end
  end

  cattr_accessor :config
end

require_relative '../lib/email_alert_api/config'
EmailAlertAPI.config = EmailAlertAPI::Config.new(Rails.env)
