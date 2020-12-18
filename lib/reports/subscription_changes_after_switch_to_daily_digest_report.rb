require "csv"

class Reports::SubscriptionChangesAfterSwitchToDailyDigestReport
  def self.call
    list_slugs = CSV.read(Rails.root.join("config/daily_digest_migration_lists.csv"), headers: true)
                    .map { |c| c.fetch("slug") }

    ended_subscriptions = Subscription
      .joins(:subscriber_list)
      .where(source: :bulk_immediate_to_digest, "subscriber_lists.slug": list_slugs)
      .where.not(ended_at: nil)

    most_recent_subscriptions = ended_subscriptions.map do |s|
      Subscription
        .includes(:subscriber_list)
        .where(subscriber_id: s.subscriber_id, subscriber_list_id: s.subscriber_list_id)
        .where("updated_at > ?", s.created_at)
        .order(updated_at: :desc)
        .first
    end

    puts(CSV.generate do |csv|
      csv << %w[created_at ended_at frequency subscriber_id subscriber_list_slug]

      most_recent_subscriptions.each do |s|
        csv << [s.created_at, s.ended_at, s.frequency, s.subscriber_id, s.subscriber_list.slug]
      end
    end)
  end
end
