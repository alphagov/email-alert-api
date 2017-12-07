class HealthcheckController < ApplicationController
  def check
    render json: healthcheck.details.merge(status: healthcheck.status)
  end

private

  def healthcheck
    @healthcheck ||= Healthcheck.new
  end
end
