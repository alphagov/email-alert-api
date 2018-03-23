class SubscriptionsController < ApplicationController
  def create
    return render json: { id: 0 }, status: :created if smoke_test_address?

    existing_subscription = nil
    subscription = nil

    Subscription.transaction do
      existing_subscription = Subscription.active.lock.find_by(
        subscriber: subscriber,
        subscriber_list: subscribable,
      )

      existing_subscription.end(reason: :frequency_changed) if existing_subscription

      subscriber.activate! if subscriber.deactivated?

      subscription = Subscription.create!(
        subscriber: subscriber,
        subscriber_list: subscribable,
        frequency: frequency,
        signon_user_uid: current_user.uid,
        source: existing_subscription ? :frequency_changed : :user_signed_up
      )
    end

    status = existing_subscription ? :ok : :created
    render json: { id: subscription.id }, status: status
  end

  def show
    subscription = Subscription.find(subscription_params.require(:id))
    render json: { subscription: subscription }
  end

  def update
    existing_subscription = nil
    subscription = nil

    Subscription.transaction do
      existing_subscription = Subscription.active.lock.find(
        subscription_params.require(:id)
      )

      existing_subscription.end(reason: :frequency_changed)

      begin
        subscription = Subscription.create!(
          subscriber: existing_subscription.subscriber,
          subscriber_list: existing_subscription.subscriber_list,
          frequency: frequency,
          signon_user_uid: current_user.uid,
          source: :frequency_changed
        )
      rescue ArgumentError
        # This happens if a frequency is provided that isn't included
        # in the enum which is in the Subscription model
        raise ActiveRecord::RecordInvalid
      end
    end

    render json: { subscription: subscription }, status: :ok
  end

private

  def smoke_test_address?
    address.end_with?("@notifications.service.gov.uk")
  end

  def subscriber
    @subscriber ||= begin
                      found = Subscriber.find_by_address(address)
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
    @subscribable ||= SubscriberList.find(subscription_params.require(:subscribable_id))
  end

  def frequency
    subscription_params.fetch(:frequency, "immediately").to_sym
  end

  def subscription_params
    params.permit(:id, :address, :subscribable_id, :frequency)
  end
end
