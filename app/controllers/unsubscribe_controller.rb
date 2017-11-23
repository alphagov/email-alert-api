class UnsubscribeController < ApplicationController
  def unsubscribe
    uuid = params.fetch(:uuid)

    subscription = Subscription.find_by!(uuid: uuid)
    subscription.destroy

    render plain: "deleted #{uuid}", status: 200
  end
end
