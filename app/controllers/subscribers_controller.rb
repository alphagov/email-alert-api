class SubscribersController < ApplicationController
  DEFAULT_ORDERING = "-created_at".freeze
  ORDER_FIELDS = %w[title created_at].freeze

  def subscriptions
    if !valid_ordering_param?
      return render json: { error: "Order paramater not valid" }, status: :unprocessable_entity
    end

    render json: { subscriber: subscriber.as_json, subscriptions: ordered_subscriptions }
  end

  def change_address
    subscriber.update!(address: new_address)
    render json: { subscriber: subscriber }
  end

private

  def valid_ordering_param?
    allowed_sort_columns = ORDER_FIELDS.flat_map do |item|
      [item, "-#{item}"]
    end

    allowed_sort_columns.include?(params.fetch(:order, DEFAULT_ORDERING))
  end

  def subscription_ordering
    order = params.fetch(:order, DEFAULT_ORDERING)
    direction = order.chars.first == "-" ? "desc" : "asc"
    column = order.delete_prefix("-")

    order_column = (column == "title" ? "subscriber_lists.title" : "created_at")
    { "#{order_column}": direction }
  end

  def subscriber
    @subscriber ||= Subscriber.find(id)
  end

  def ordered_subscriptions
    Subscription
      .active
      .joins(:subscriber_list)
      .includes(:subscriber_list)
      .where(subscriber: subscriber)
      .order(subscription_ordering)
      .order(id: :asc)
      .as_json(include: :subscriber_list)
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
