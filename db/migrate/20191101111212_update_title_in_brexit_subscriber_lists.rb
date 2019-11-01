class UpdateTitleInBrexitSubscriberLists < ActiveRecord::Migration[5.2]
  OLD_TITLE = "Your Get ready for Brexit results".freeze
  NEW_TITLE = "How to prepare for a no deal Brexit".freeze

  def up
    if subscriber_lists.any? { |list| list.title != OLD_TITLE }
      raise "Some Brexit related lists have unexpected titles"
    end

    subscriber_lists.update_all(title: NEW_TITLE)
  end

  def down
    if subscriber_lists.any? { |list| list.title != NEW_TITLE }
      raise "Some Brexit related lists have unexpected titles"
    end

    subscriber_lists.update_all(title: OLD_TITLE)
  end

  def subscriber_lists
    @subscriber_lists ||= SubscriberList.where("(tags->'brexit_checklist_criteria')::json IS NOT NULL")
  end
end
