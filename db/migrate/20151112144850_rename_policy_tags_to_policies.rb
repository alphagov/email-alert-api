class RenamePolicyTagsToPolicies < ActiveRecord::Migration
  def up
    SubscriberListQuery.new(query_field: :tags).subscriber_lists_with_key(:policy).each do |sl|
      sl.tags = { policies: sl.tags[:policy] }
      sl.save!
    end
  end

  def down
    SubscriberListQuery.new(query_field: :tags).subscriber_lists_with_key(:policies).each do |sl|
      sl.tags = { policy: sl.tags[:policies] }
      sl.save!
    end
  end
end
