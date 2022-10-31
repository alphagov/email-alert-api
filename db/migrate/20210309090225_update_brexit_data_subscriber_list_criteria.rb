class UpdateBrexitDataSubscriberListCriteria < ActiveRecord::Migration[6.1]
  CSV_FILE = Rails.root.join("db/migrate/data/subscriber-list-criteria-2021-03-08.csv").freeze

  def up
    update_criteria("new_criteria")
  end

  def down
    update_criteria("matching_criteria")
  end

private

  def update_criteria(criteria_field_name)
    CSV.foreach(CSV_FILE, headers: true) do |row|
      criteria = JSON.parse(row[criteria_field_name]).to_h
      tags = criteria["tags"]

      subscriber_list = SubscriberList.find_by(slug: row["slug"])
      subscriber_list.update!(tags:) if subscriber_list
    end
  end
end
