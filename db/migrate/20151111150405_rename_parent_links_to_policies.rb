class RenameParentLinksToPolicies < ActiveRecord::Migration
  def up
    SubscriberListQuery.new(query_field: :links).subscriber_lists_with_key(:parent).each do |sl|
      sl.links = { policies: sl.links[:parent] }
      sl.save!
    end
  end

  def down
    SubscriberListQuery.new(query_field: :links).subscriber_lists_with_key(:policies).each do |sl|
      sl.links = { parent: sl.links[:policies] }
      sl.save!
    end
  end
end
