desc "Fix bug by backfilling updated at for ended subscriptions"
task backfill_updated_at_for_ended_subscriptions: :environment do
  ended_subscriptions = Subscription.where("ended_at > updated_at")

  ended_subscriptions.find_each do |sub|
    sub.update!(updated_at: sub.ended_at)
  end
end
