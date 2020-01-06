class HealthcheckController < ApplicationController
  skip_before_action :authorise

  def index
    healthcheck = GovukHealthcheck.healthcheck([
                    GovukHealthcheck::SidekiqRedis,
                    GovukHealthcheck::ActiveRecord,
                    Healthcheck::Messages,
                    Healthcheck::DigestRuns,
                    Healthcheck::QueueLatency,
                    Healthcheck::QueueSize,
                    Healthcheck::RetrySize,
                    Healthcheck::SubscriptionContents,
                  ])
    render json: healthcheck
  end
end
