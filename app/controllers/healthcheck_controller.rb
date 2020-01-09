class HealthcheckController < ApplicationController
  skip_before_action :authorise

  def index
    healthcheck = GovukHealthcheck.healthcheck([
                    GovukHealthcheck::SidekiqRedis,
                    GovukHealthcheck::ActiveRecord,
                    Healthcheck::QueueLatency,
                    Healthcheck::QueueSize,
                    Healthcheck::RetrySize,
                  ])
    render json: healthcheck
  end
end
