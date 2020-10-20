class SubscriptionsController < ApplicationController
  def create
    subscriber = Subscriber.resilient_find_or_create(
      address,
      signon_user_uid: current_user.uid,
    )

    subscription, email, status = subscriber.with_lock do
      deactivated_subscriber = subscriber.deactivated?
      subscriber.activate if deactivated_subscriber

      existing_subscription = Subscription.active.find_by(
        subscriber: subscriber,
        subscriber_list: subscriber_list,
      )

      create_new_subscription = frequency != existing_subscription&.frequency

      if create_new_subscription
        existing_subscription&.end(reason: :frequency_changed)
        new_subscription = Subscription.create!(
          subscriber: subscriber,
          subscriber_list: subscriber_list,
          frequency: frequency,
          signon_user_uid: current_user.uid,
          source: existing_subscription ? :frequency_changed : :user_signed_up,
        )
      end

      subscription = new_subscription || existing_subscription
      email = if create_new_subscription || deactivated_subscriber
                SubscriptionConfirmationEmailBuilder.call(subscription: subscription)
              end

      [subscription, email, existing_subscription ? :ok : :created]
    end

    if email
      SendEmailWorker.perform_async_in_queue(email.id, queue: :send_email_transactional)
    end

    render json: { id: subscription.id }, status: status
  end

  def show
    subscription = Subscription.find(subscription_params.require(:id))
    render json: { subscription: subscription }
  end

  def update
    existing_subscription = Subscription.active.find(
      subscription_params.require(:id),
    )

    if frequency == existing_subscription.frequency
      render json: { subscription: existing_subscription }
      return
    end

    new_subscription = existing_subscription.subscriber.with_lock do
      existing_subscription.end(reason: :frequency_changed)

      Subscription.create!(
        subscriber: existing_subscription.subscriber,
        subscriber_list: existing_subscription.subscriber_list,
        frequency: frequency,
        signon_user_uid: current_user.uid,
        source: :frequency_changed,
      )
    rescue ArgumentError
      # This happens if a frequency is provided that isn't included
      # in the enum which is in the Subscription model
      raise ActiveRecord::RecordInvalid
    end

    render json: { subscription: new_subscription }
  end

  def latest_matching
    subscription = Subscription.find(subscription_params.require(:id))
    render json: { subscription: FindLatestMatchingSubscription.call(subscription) }, status: :ok
  end

private

  def address
    subscription_params.require(:address)
  end

  def subscriber_list
    @subscriber_list ||= SubscriberList.find(subscriber_list_id)
  end

  def subscriber_list_id
    subscription_params[:subscribable_id] || subscription_params.require(:subscriber_list_id)
  end

  def frequency
    subscription_params.fetch(:frequency, "immediately")
  end

  def subscription_params
    params.permit(:id, :address, :subscribable_id, :subscriber_list_id, :frequency)
  end
end
