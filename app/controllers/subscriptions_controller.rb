class SubscriptionsController < ActionController::Base
  def create
    subscription = Subscription.find_or_initialize_by(
      subscriber: subscriber,
      subscriber_list: subscribable,
    )

    if subscription.new_record?
      subscription.save!
      status = :created
    else
      status = :ok
    end

    render json: { id: subscription.id }, status: status
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
