# rubocop:disable Lint/UnreachableCode

class RenamePolicyTagsToPolicies < ActiveRecord::Migration[4.2]
  def up
    return

    subscriber_lists_with_key(:policy).each do |sl|
      sl.tags = { policies: sl.tags[:policy] }
      sl.save!
    end
  end

  def down
    subscriber_lists_with_key(:policies).each do |sl|
      sl.tags = { policy: sl.tags[:policies] }
      sl.save!
    end
  end

  def subscriber_lists_with_key(key)
    SubscriberList.where("(tags -> :key) IS NOT NULL", key: key)
  end
end

# rubocop:enable Lint/UnreachableCode
