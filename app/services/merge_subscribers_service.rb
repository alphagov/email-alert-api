class MergeSubscribersService
  include Callable

  def initialize(subscriber_to_keep:, subscriber_to_absorb:, current_user:)
    @subscriber_to_keep = subscriber_to_keep
    @subscriber_to_absorb = subscriber_to_absorb
    @current_user = current_user
  end

  def call
    return unless subscriber_to_absorb

    merge_subscribers!
    subscriber_to_absorb.update!(address: nil, updated_at: Time.zone.now)
  end

private

  attr_reader :subscriber_to_keep, :subscriber_to_absorb, :current_user

  def merge_subscribers!
    active_subscriptions = subscriptions_by_list(subscriber_to_keep.active_subscriptions)

    subscriber_to_absorb.active_subscriptions.each do |other|
      keep_most_frequent(
        active_subscriptions[other.subscriber_list_id],
        other,
      )
    end
  end

  def subscriptions_by_list(subscriptions)
    subscriptions.index_by(&:subscriber_list_id)
  end

  def keep_most_frequent(original, other)
    if original
      if original.frequency <= other.frequency
        other.end(reason: :subscriber_merged)
        return original
      else
        original.end(reason: :subscriber_merged)
      end
    end

    other.end(reason: :subscriber_merged)
    new_subscription = CreateSubscriptionService.call(
      other.subscriber_list,
      subscriber_to_keep,
      other.frequency,
      current_user,
    )[:record]

    new_subscription.update!(source: :subscriber_merged)
    new_subscription
  end
end
