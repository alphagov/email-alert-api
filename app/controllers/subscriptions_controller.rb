class SubscriptionsController < ApplicationController
  def create
    subscription = Subscription.find_or_initialize_by(
      subscriber: subscriber,
      subscriber_list: subscribable,
    )

    status = subscription.new_record? ? :created : :ok

    subscription.frequency = frequency
    subscription.signon_user_uid = current_user.uid
    subscription.save!

    render json: { id: subscription.id }, status: status
  end

private

  def subscriber
    @subscriber ||= begin
                      address = subscription_params.require(:address)
                      found = Subscriber.find_by(address: address)
                      found || Subscriber.create!(
                        address: address,
                        signon_user_uid: current_user.uid,
                      )
                    end
  end

  def subscribable
    SubscriberList.find(subscription_params.require(:subscribable_id))
  end

  def frequency
    subscription_params.fetch(:frequency, "immediately").to_sym
  end

  def subscription_params
    params.permit(:address, :subscribable_id, :frequency)
  end
end
