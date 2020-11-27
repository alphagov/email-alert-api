require "yaml"
require "erb"

module EmailAlertAPI
  class Config
    def initialize(environment)
      @environment = environment || "development"
    end

    def app_root
      Rails.root
    end

    def notify_client
      Notifications::Client.new(Rails.application.secrets.notify_api_key)
    end

    def email_service
      @email_service ||= email_service_config.symbolize_keys.freeze
    end

  private

    def environment_config(path:)
      YAML.safe_load(
        ERB.new(File.read(path)).result, [], [], true
      ).fetch(@environment)
    end

    def email_service_config_path
      File.join(app_root, "config", "email_service.yml")
    end

    def email_service_config
      environment_config(path: email_service_config_path)
    end
  end
end
