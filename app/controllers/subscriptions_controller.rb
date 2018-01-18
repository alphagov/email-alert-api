class SubscriptionsController < ApplicationController
  def create
    subscription = Subscription.find_or_initialize_by(
      subscriber: subscriber,
      subscriber_list: subscribable,
    )

    status = subscription.new_record? ? :created : :ok

    subscription.frequency = frequency
    subscription.save!

    render json: { id: subscription.id }, status: status
  end

private

  def subscriber
    Subscriber.find_or_create_by!(address: subscription_params[:address])
  end

  def subscribable
    SubscriberList.find(subscription_params[:subscribable_id])
  end

  def frequency
    subscription_params.fetch(:frequency, "immediately").to_sym
  end

  def subscription_params
    params.require(:address)
    params.require(:subscribable_id)
    params.permit(:address, :subscribable_id, :frequency)
  end
end
