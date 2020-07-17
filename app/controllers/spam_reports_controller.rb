class SpamReportsController < ApplicationController
  wrap_parameters false

  def create
    delivery_attempt = DeliveryAttempt.find(params[:reference])
    SpamReportService.call(delivery_attempt)
    head :no_content
  end

private

  def authorise
    authorise_user!("status_updates")
  end
end
