class UpdateBrexitCheckerTitles < ActiveRecord::Migration[5.2]
  OLD_TITLE = "How to prepare for a no deal Brexit".freeze
  NEW_TITLE = "Get ready for 2021".freeze

  def up
    SubscriberList.where(title: OLD_TITLE).update_all(title: NEW_TITLE)
  end

  def down
    SubscriberList.where(title: NEW_TITLE).update_all(title: OLD_TITLE)
  end
end
