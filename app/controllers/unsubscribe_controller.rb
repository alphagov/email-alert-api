class UnsubscribeController < ApplicationController
  def unsubscribe
    Unsubscribe.subscription!(subscription)
    render plain: "deleted #{uuid}", status: 200
  end

private

  def subscription
    Subscription.find_by!(uuid: uuid)
  end

  def uuid
    params.fetch(:uuid)
  end
end
