# rubocop:disable Lint/UnreachableCode

class RemovePolicySubscriberListsWithErroneousLinks < ActiveRecord::Migration[4.2]
  def up
    return

    subscriber_lists_with_key(:policies).each(&:destroy!)
  end

  def down
    # noop
  end

  def subscriber_lists_with_key(key)
    SubscriberList.where("(tags -> :key) IS NOT NULL", key: key)
  end
end

# rubocop:enable Lint/UnreachableCode
