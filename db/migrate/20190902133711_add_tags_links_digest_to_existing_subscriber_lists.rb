class AddTagsLinksDigestToExistingSubscriberLists < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    SubscriberList.where("tags_digest IS NULL AND links_digest IS NULL").find_each do |list|
      list.tags_digest = HashDigest.new(list.tags).generate
      list.links_digest = HashDigest.new(list.links).generate
      list.save!
    end
  end
end
