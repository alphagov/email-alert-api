class RemovePolicySubscriberListsWithErroneousLinks < ActiveRecord::Migration
  def up
    SubscriberListQuery.new(query_field: :tags).subscriber_lists_with_key(:policies).each do |sl|
      sl.destroy!
    end
  end

  def down
    # noop
  end
end
