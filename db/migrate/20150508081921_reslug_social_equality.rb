class ReslugSocialEquality < ActiveRecord::Migration
  def up
    list = SubscriberList.where_tags_equal(policies: ["social-equality"]).first

    if list
      list.update(tags: {
        policies: ["equality"]
      })
      list.reload
      puts %{Reslugged "social-equality" to #{list.tags[:policies]}}
    else
      puts %{Could not find a subscriber list with the policy tag "social-equality"}
    end
  end

  def down
    list = SubscriberList.where_tags_equal(policies: ["equality"]).first

    if list
      list.update(tags: {
        policies: ["social-equality"]
      })
      list.reload
      puts %{Reslugged "equality" to #{list.tags[:policies]}}
    else
      puts %{Could not find a subscriber list with the policy tag "equality"}
    end
  end
end
