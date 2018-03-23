class SubscribersController < ApplicationController
  def subscriptions
    subscriptions = Subscription.active.
      includes(:subscriber_list).
      where(subscriber: subscriber).
      order('subscriber_lists.title').
      as_json(include: :subscriber_list)

    render json: { subscriber: subscriber.as_json, subscriptions: subscriptions }
  end

  def change_address
    subscriber.update!(address: new_address)
    render json: { subscriber: subscriber }
  end

private

  def subscriber
    @subscriber ||= Subscriber.find(id)
  end

  def new_address
    subscriber_params.require(:new_address)
  end

  def id
    subscriber_params.require(:id)
  end

  def subscriber_params
    params.permit(:id, :new_address)
  end
end
