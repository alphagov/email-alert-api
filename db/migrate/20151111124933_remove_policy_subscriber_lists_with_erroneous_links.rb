class RemovePolicySubscriberListsWithErroneousLinks < ActiveRecord::Migration
  def up
    subscriber_lists_with_key(:policies).each(&:destroy!)
  end

  def down
    # noop
  end

  def subscriber_lists_with_key(key)
    SubscriberList.where("(tags -> :key) IS NOT NULL", key: key)
  end
end
