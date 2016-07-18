desc "Copy over tags and links into new json field"
task json_migration: :environment do
  SubscriberList.all.each do |subscriber_list|
    subscriber_list.update_columns(
      tags_json: subscriber_list.tags,
      links_json: subscriber_list.links,
    )
  end
end
