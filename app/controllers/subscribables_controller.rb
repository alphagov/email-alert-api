class SubscribablesController < ApplicationController
  def show
    render json: subscribable_json
  end

private

  def subscribable_json
    subscriber_list = SubscriberList.find_by(gov_delivery_id: params[:gov_delivery_id])
    { subscribable: subscriber_list.attributes }
  end
end
