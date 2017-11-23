class UnsubscribeController < ApplicationController
  def unsubscribe
    uuid = params.fetch(:uuid)

    subscription = Subscription.find_by!(uuid: uuid)
    subscription.destroy
  end
end
