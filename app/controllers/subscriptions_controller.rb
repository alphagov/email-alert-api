class SubscriptionsController < ApplicationController
  def create
    return render json: { id: 0 }, status: :created if smoke_test_address?

    subscription = Subscription.find_or_initialize_by(
      subscriber: subscriber,
      subscriber_list: subscribable,
    )

    status = subscription.new_record? ? :created : :ok

    subscription.deleted_at = nil
    subscription.frequency = frequency
    subscription.signon_user_uid = current_user.uid
    subscription.save!
    render json: { id: subscription.id }, status: status
  end

private

  def smoke_test_address?
    address.end_with?("@notifications.service.gov.uk")
  end

  def subscriber
    @subscriber ||= begin
                      found = Subscriber.find_by(address: address)
                      found || Subscriber.create!(
                        address: address,
                        signon_user_uid: current_user.uid,
                      )
                    end
  end

  def address
    subscription_params.require(:address)
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
