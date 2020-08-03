class SpamReportsController < ApplicationController
  wrap_parameters false

  def create
    subscriber = Subscriber.find_by(address: params[:to])
    SpamReportService.call(subscriber) if subscriber
    head :no_content
  end

private

  def authorise
    authorise_user!("status_updates")
  end
end
