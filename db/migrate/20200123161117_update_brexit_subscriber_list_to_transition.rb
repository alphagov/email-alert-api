class UpdateBrexitSubscriberListToTransition < ActiveRecord::Migration[5.2]
  def up
    subscriber_list = SubscriberList.find_by_slug("brexit-p")
    return if subscriber_list.nil?

    subscriber_list.slug = "transition-p"
    subscriber_list.title = "Transition"
    subscriber_list.save
  end

  def down
    subscriber_list = SubscriberList.find_by_slug("transition-p")
    return if subscriber_list.nil?

    subscriber_list.slug = "brexit-p"
    subscriber_list.title = "Brexit"
    subscriber_list.save
  end
end
