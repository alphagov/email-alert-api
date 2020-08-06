class SpamReportsController < ApplicationController
  wrap_parameters false

  def create
    subscriber = Subscriber.find_by_address(params[:to])
    UnsubscribeAllService.call(subscriber, :marked_as_spam) if subscriber
    head :no_content
  end

private

  def authorise
    authorise_user!("status_updates")
  end
end
