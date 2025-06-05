class SubscriptionsController < ApplicationController
  def create
    subscriber = Subscriber.resilient_find_or_create(
      address,
      signon_user_uid: current_user.uid,
    )

    subscription = CreateSubscriptionService.call(
      subscriber_list,
      subscriber,
      frequency,
      current_user,
    )

    send_confirmation_email(subscription)

    render json: { subscription: subscription[:record] }
  end

  def show
    subscription = Subscription.find(subscription_params.require(:id))
    render json: { subscription: }
  end

  def update
    existing_subscription = Subscription.active.find(
      subscription_params.require(:id),
    )

    new_subscription = CreateSubscriptionService.call(
      existing_subscription.subscriber_list,
      existing_subscription.subscriber,
      frequency,
      current_user,
    )

    render json: { subscription: new_subscription[:record] }
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
    subscriber_list_id = subscription_params.require(:subscriber_list_id)
    @subscriber_list ||= SubscriberList.find(subscriber_list_id)
  end

  def frequency
    subscription_params.fetch(:frequency, "immediately")
  end

  def subscription_params
    params.permit(:id, :address, :subscriber_list_id, :frequency)
  end

  def send_confirmation_email(subscription)
    return if params[:skip_confirmation_email]
    return unless subscription[:new_record]

    email = SubscriptionConfirmationEmailBuilder.call(subscription: subscription[:record])
    SendEmailJob.perform_async_in_queue(email.id, queue: :send_email_transactional)
  end
end
