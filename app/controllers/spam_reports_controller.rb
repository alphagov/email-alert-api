class SpamReportsController < ApplicationController
  wrap_parameters false

  def create
    email = DeliveryAttempt.find(params[:reference]).email
    SpamReportService.call(email)
    head :no_content
  end

private

  def authorise
    authorise_user!("status_updates")
  end
end
