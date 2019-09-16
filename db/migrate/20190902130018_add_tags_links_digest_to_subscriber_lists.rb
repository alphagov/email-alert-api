class AddTagsLinksDigestToSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    add_column :subscriber_lists, :tags_digest, :string
    add_column :subscriber_lists, :links_digest, :string
  end
end
