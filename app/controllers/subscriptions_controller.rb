class SubscriptionsController < ActionController::Base
  def create
    subscription = Subscription.create!(
      subscriber: subscriber,
      subscriber_list: subscribable,
    )

    render json: { id: subscription.id }, status: :created
  end

private

  def subscriber
    Subscriber.find_or_create_by(address: subscription_params[:address])
  end

  def subscribable
    SubscriberList.find(subscription_params[:subscribable_id])
  end

  def subscription_params
    params.require(:address)
    params.require(:subscribable_id)
    params.permit(:address, :subscribable_id)
  end
end
