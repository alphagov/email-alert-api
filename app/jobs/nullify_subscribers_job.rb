class NullifySubscribersJob < ApplicationJob
  def perform
    run_with_advisory_lock(Subscriber, "nullify") do
      nullifyable_subscribers.each do |s|
        begin
          GdsApi.account_api.delete_user_by_subject_identifier(subject_identifier: s.govuk_account_id) unless s.govuk_account_id.nil?
        rescue GdsApi::HTTPNotFound
          Rails.logger.warn("NullifySubscribersJob tried to remove account id #{s.govuk_account_id}, but couldn't find it.")
        end
        s.update!(address: nil, govuk_account_id: nil, updated_at: Time.zone.now)
      end
    end
  end

private

  def nullifyable_subscribers
    recently_active_subscriptions = Subscription
      .where("subscriptions.subscriber_id = subscribers.id")
      .where("ended_at IS NULL OR ended_at > ?", nullifyable_period)
      .arel.exists

    Subscriber
      .not_nullified
      .where("created_at < ?", nullifyable_period)
      .where.not(recently_active_subscriptions)
  end

  def nullifyable_period
    @nullifyable_period ||= 28.days.ago
  end
end
