class UnsubscribeController < ApplicationController
  def unsubscribe
    Unsubscribe.subscription!(subscription)
  end

private

  def subscription
    Subscription.find_by!(uuid: uuid)
  end

  def uuid
    params.fetch(:uuid)
  end
end
