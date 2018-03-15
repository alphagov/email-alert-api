class SubscribersController < ApplicationController
  def subscriptions
    subscriptions = Subscription.active.
      includes(:subscriber_list).
      where(subscriber: subscriber).
      order('subscriber_lists.title').
      as_json(include: :subscriber_list)

    render json: { subscriber: subscriber.as_json, subscriptions: subscriptions }
  end

private

  def subscriber
    @subscriber ||= Subscriber.find_by!("LOWER(address) = ?", address.downcase)
  end

  def address
    subscriber_params.require(:address)
  end

  def subscriber_params
    params.permit(:address)
  end
end
