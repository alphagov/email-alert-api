class SpamReportsController < ApplicationController
  wrap_parameters false

  def create
    delivery_attempt = DeliveryAttempt.find(params[:reference])
    UnsubscribeService.spam_report!(delivery_attempt)
    head :no_content
  end

private

  def authorise
    authorise_user!("status_updates")
  end
end
