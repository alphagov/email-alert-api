class DeduplicateEsfaSubscriberList < ActiveRecord::Migration[5.2]
  def change
    old_list = SubscriberList.find_by(
      slug: "education-and-education-and-skills-funding-agency"
    )
    new_list = SubscriberList.find_by(
      slug: "education-and-skills-funding-agency"
    )

    if old_list && new_list
      puts "#{old_list.subscriptions.count} subscriptions for '#{old_list.title}'"
      puts "#{new_list.subscriptions.count} subscriptions for '#{new_list.title}'"
      puts "#{(old_list.subscribers & new_list.subscribers).count} subscribers exist in both lists"

      scope = Subscription
        .where(subscriber_list: old_list)
        .where.not(subscriber: new_list.subscribers)

      puts "#{scope.count} subscriptions to migrate from '#{old_list.title}' to '#{new_list.title}'"

      updated = scope.update_all(subscriber_list_id: new_list.id)

      puts "Added #{updated} subscriptions to '#{new_list.title}'"

      if Subscription.where(subscriber_list: old_list).destroy_all && old_list.destroy
        puts "Deleted '#{old_list.title}' with remaining subscriptions"
      end
    end
  end
end
