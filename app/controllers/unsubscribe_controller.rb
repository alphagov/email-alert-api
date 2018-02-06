class UnsubscribeController < ApplicationController
  def unsubscribe
    UnsubscribeService.subscription!(subscription)
  end

private

  def subscription
    Subscription.not_deleted.find_by!(uuid: uuid)
  end

  def uuid
    params.fetch(:uuid)
  end
end
