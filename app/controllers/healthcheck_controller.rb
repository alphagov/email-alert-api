class HealthcheckController < ApplicationController
  skip_before_action :authorise

  def index
    healthcheck = GovukHealthcheck.healthcheck([
                    GovukHealthcheck::SidekiqRedis,
                    GovukHealthcheck::ActiveRecord,
                    Healthcheck::ContentChanges,
                    Healthcheck::Messages,
                    Healthcheck::DigestRuns,
                    Healthcheck::QueueLatency,
                    Healthcheck::QueueSize,
                    Healthcheck::RetrySize,
                    Healthcheck::StatusUpdates,
                    Healthcheck::SubscriptionContents,
                    Healthcheck::TechnicalFailures,
                    Healthcheck::InternalFailures,
                  ])
    render json: healthcheck
  end
end
