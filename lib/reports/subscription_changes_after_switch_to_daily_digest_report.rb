class Reports::SubscriptionChangesAfterSwitchToDailyDigestReport
  def self.call
    updated_subscriptions = Subscription.where(source: 4).where.not(ended_at: nil)

    newer_subscriptions = updated_subscriptions.all.flat_map do |s|
      Subscription
        .includes(:subscriber_list)
        .where(subscriber_id: s.subscriber_id, subscriber_list_id: s.subscriber_list_id)
        .where("updated_at > ?", s.created_at).order(updated_at: :desc).first
    end

    puts(CSV.generate do |csv|
      csv << %w[created_at ended_at frequency subscriber_id subscriber_list_slug]

      newer_subscriptions.to_a.each do |s|
        csv << [s.created_at, s.ended_at, s.frequency, s.subscriber_id, s.subscriber_list.slug]
      end
    end)
  end
end
