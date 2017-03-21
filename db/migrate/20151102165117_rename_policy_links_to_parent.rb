class RenamePolicyLinksToParent < ActiveRecord::Migration
  def up
    subscriber_lists_with_key(:policy).each do |list|
      content_id = list.links[:policy]
      list.links = {parent: content_id}
      list.save!
    end
  end

  def down
    subscriber_lists_with_key(:parent).each do |list|
      content_id = list.links[:parent]
      list.links = {policy: content_id}
      list.save!
    end
  end

  def subscriber_lists_with_key(key)
    SubscriberList.where("(links -> :key) IS NOT NULL", key: key)
  end
end
