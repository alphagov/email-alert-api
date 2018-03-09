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

    def notify
      @notify ||= notify_environment_config.symbolize_keys.freeze
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

    def notify_config_path
      File.join(app_root, "config", "notify.yml")
    end

    def notify_environment_config
      environment_config(path: notify_config_path)
    end

    def email_service_config_path
      File.join(app_root, "config", "email_service.yml")
    end

    def email_service_config
      environment_config(path: email_service_config_path)
    end
  end
end
