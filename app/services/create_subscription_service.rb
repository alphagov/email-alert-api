class CreateSubscriptionService < ApplicationService
  attr_reader :subscriber_list, :subscriber, :frequency, :current_user

  def initialize(subscriber_list, subscriber, frequency, current_user)
    @subscriber_list = subscriber_list
    @subscriber = subscriber
    @frequency = frequency
    @current_user = current_user
  end

  def call
    ApplicationRecord.transaction do
      subscriber.lock!

      subscription = Subscription.find_by(
        subscriber_list: subscriber_list,
        subscriber: subscriber,
      )

      if subscription
        return subscription if subscription.frequency == frequency

        subscription.end(reason: :frequency_changed)
      end

      Subscription.create!(
        subscriber: subscriber,
        subscriber_list: subscriber_list,
        frequency: frequency,
        signon_user_uid: current_user.uid,
        source: subscription ? :frequency_changed : :user_signed_up,
      )
    rescue ArgumentError
      # This happens if a frequency is provided that isn't included
      # in the enum which is in the Subscription model
      raise ActiveRecord::RecordInvalid
    end
  end
end
