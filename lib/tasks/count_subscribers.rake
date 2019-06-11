namespace :query do
  desc "Query how many active subscribers there are to the given subscription slug"
  task :count_subscribers, %i[subscription_list_slug] => :environment do |_t, args|
    slug = args[:subscription_list_slug]
    subscription_lists = SubscriberList.where(slug: slug)
    raise "There is no SubscriberList called '#{slug}'" unless subscription_lists.count == 1

    active_subscriptions = subscription_lists.first.subscriptions.where(ended_at: nil)
    puts """
      The SubscriberList '#{slug}' has #{active_subscriptions.count} active subscriptions, of which:
        - #{active_subscriptions.where(frequency: 0).count} are signed up for Immediate updates
        - #{active_subscriptions.where(frequency: 1).count} are signed up for Daily updates
        - #{active_subscriptions.where(frequency: 2).count} are signed up for Weekly updates
    """
  end
end
