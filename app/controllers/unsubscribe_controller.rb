class UnsubscribeController < ApplicationController
  def unsubscribe
    UnsubscribeService.subscription!(subscription)
  end

private

  def subscription
    Subscription.not_deleted.find(id)
  end

  def id
    params.fetch(:id)
  end
end
