class SpamReportsController < ApplicationController
  wrap_parameters false

  def create
    delivery_attempt_id = params[:reference]
    subscriber_email_address = params[:to]
    SpamReportService.call(delivery_attempt_id, subscriber_email_address)
    head :no_content
  end

private

  def authorise
    authorise_user!("status_updates")
  end
end
