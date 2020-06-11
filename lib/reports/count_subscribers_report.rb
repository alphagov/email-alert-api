class Reports::CountSubscribersReport
  def call(slug:)
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
