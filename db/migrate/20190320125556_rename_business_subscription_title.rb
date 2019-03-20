class RenameBusinessSubscriptionTitle < ActiveRecord::Migration[5.2]
  def change
    subscriber_list = SubscriberList.find_by(slug: "find-eu-exit-guidance-for-your-business-appear-in-find-eu-exit-guidance-business-finder")

    if subscriber_list
      subscriber_list.title = "EU Exit guidance for your business or organisation"
      subscriber_list.save!
    end
  end
end
