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

    def gov_delivery
      @gov_delivery ||= environment_config.symbolize_keys.freeze
    end

    def redis_config
      YAML.safe_load(ERB.new(File.read(redis_config_path)).result).symbolize_keys
    end

    def notify
      @notify ||= notify_environment_config.symbolize_keys.freeze
    end

    def email_service_provider
      @email_service_provider ||= email_service.fetch(:provider).freeze
    end

    def email_service
      @email_service ||= email_service_config.symbolize_keys.freeze
    end

  private

    def redis_config_path
      File.join(app_root, "config", "redis.yml")
    end

    def gov_delivery_config_path
      File.join(app_root, "config", "gov_delivery.yml")
    end

    def environment_config
      YAML.safe_load(ERB.new(File.read(gov_delivery_config_path)).result).fetch(@environment)
    end

    def notify_config_path
      File.join(app_root, "config", "notify.yml")
    end

    def notify_environment_config
      YAML.safe_load(ERB.new(File.read(notify_config_path)).result).fetch(@environment)
    end

    def email_service_config_path
      File.join(app_root, "config", "email_service.yml")
    end

    def email_service_config
      YAML.safe_load(ERB.new(File.read(email_service_config_path)).result).fetch(@environment)
    end
  end
end
