class UnsubscribeController < ApplicationController
  def unsubscribe
    UnsubscribeService.subscription!(subscription)
  end

private

  def subscription
    Subscription.active.find(id)
  end

  def id
    params.fetch(:id)
  end
end
