class AddFacetGroupLinkToEuExitSubscriberLists < ActiveRecord::Migration[5.2]
  def change
    SubscriberList.where("slug LIKE 'find-eu-exit-guidance-for-your-business%'").each do |list|
      list.links = list.links.merge(facet_groups: { any: %W(52435175-82ed-4a04-adef-74c0199d0f46) })
      list.save!
    end
  end
end
