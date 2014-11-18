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
      @gov_delivery ||= environment_config.symbolize_keys.freeze
    end

    def redis_config
      YAML.load(File.open(app_root+"config/redis.yml")).symbolize_keys
    end

  private
    def environment_config
      all_configs = YAML.load(File.open(app_root+"config/gov_delivery.yml"))

      all_configs.fetch(@environment).tap do |env_config|
        env_config.merge!(environment_credentials) if ENV["GOVDELIVERY_USERNAME"]
      end
    end

    def environment_credentials
      {
        "username" => ENV["GOVDELIVERY_USERNAME"],
        "password" => ENV["GOVDELIVERY_PASSWORD"],
      }
    end
  end
end
