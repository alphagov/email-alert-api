namespace :query do
  desc "Query how many active subscribers there are to the given subscription slug"
  task :count_subscribers, %i[subscription_list_slug] => :environment do |_t, args|
    slug = args[:subscription_list_slug]
    subscription_list = SubscriberList.find_by!(slug: slug)
    active_subscriptions = subscription_list.subscriptions.active

    puts """
      The SubscriberList '#{slug}' has #{active_subscriptions.count} active subscriptions, of which:
        - #{active_subscriptions.where(frequency: :immediately).count} are signed up for Immediate updates
        - #{active_subscriptions.where(frequency: :daily).count} are signed up for Daily updates
        - #{active_subscriptions.where(frequency: :weekly).count} are signed up for Weekly updates
    """
  end
end
