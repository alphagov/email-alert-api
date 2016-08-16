class RemoveDupes < ActiveRecord::Migration
  def up
    # These have been checked and are just straight up bad.
    SubscriberList.where(gov_delivery_id: nil).delete_all

    # For everything else, keep the most recent.  These have also been checked.
    gov_delivery_ids = SubscriberList.group(:gov_delivery_id).having("count(*) > 1").count.keys.compact

    gov_delivery_ids.each do |gov_delivery_id|
      dupes = SubscriberList.where(gov_delivery_id: gov_delivery_id).order(:created_at).to_a
      dupes.pop # Remove the most recent
      dupes.delete_all
    end

    # Stop this from happening again, reinforced by a matching Ruby constraint
    add_index :subscriber_lists, :gov_delivery_id, unique: true
  end
end
