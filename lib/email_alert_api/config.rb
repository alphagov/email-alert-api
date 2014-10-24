require "yaml"

module EmailAlertAPI
  class Config
    def initialize(environment)
      @environment = environment || "development"
    end

    def app_root
      Rails.root
    end

    def gov_delivery
      all_configs = YAML.load(File.open(app_root+"config/gov_delivery.yml"))
      environment_config = all_configs.fetch(@environment)

      @gov_delivery ||= environment_config.symbolize_keys.freeze
    end

    def redis_config
      YAML.load(File.open(app_root+"config/redis.yml")).symbolize_keys
    end
  end
end
