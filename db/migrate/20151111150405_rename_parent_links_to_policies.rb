# rubocop:disable Lint/UnreachableCode

class RenameParentLinksToPolicies < ActiveRecord::Migration[4.2]
  def up
    return

    subscriber_lists_with_key(:parent).each do |sl|
      sl.links = { policies: sl.links[:parent] }
      sl.save!
    end
  end

  def down
    subscriber_lists_with_key(:policies).each do |sl|
      sl.links = { parent: sl.links[:policies] }
      sl.save!
    end
  end

  def subscriber_lists_with_key(key)
    SubscriberList.where("(links -> :key) IS NOT NULL", key: key)
  end
end

# rubocop:enable Lint/UnreachableCode
