# rubocop:disable Lint/UnreachableCode

class RemoveDeadPolicySubscriberList < ActiveRecord::Migration[4.2]
  def up
    return

    # This list doesn't match anything except similarly named placeholders in
    # the Content Store.
    target_list = FindExactMatch.new.call(
      policy: ["inspections-of-schools-colleges-and-children-s-services"]
    ).first

    if target_list.present?
      target_list.destroy!
    end
  end

  def down
    # noop
  end
end

# rubocop:enable Lint/UnreachableCode
