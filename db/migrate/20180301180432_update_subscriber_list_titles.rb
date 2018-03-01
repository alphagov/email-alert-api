require "csv"

class UpdateSubscriberListTitles < ActiveRecord::Migration[5.1]
  def up
    csv_file = Rails.root.join(
      "db", "migrate", "data", "subscriber-list-titles-2018-03-05.csv"
    )

    CSV.read(csv_file, headers: :first_row)
      .reject { |item| update_list(item["id"], item["gov_delivery_id"], item["title"], true) }
      .each { |item| update_list(item["id"], item["gov_delivery_id"], item["title"], false) }
  end

private

  def update_list(id, gov_delivery_id, title, first_attempt = true)
    list = SubscriberList.find(id)
    return skip_govdelivery_id(id) if list.gov_delivery_id != gov_delivery_id
    return true if list.title == title

    if SubscriberList.where(title: title).where.not(id: id).exists?
      suffix = first_attempt ? "will retry" : "wont update"
      puts "SubscriberList with id #{id} conflicts, #{suffix}"
      false
    else
      list.update!(title: title)
    end
  rescue ActiveRecord::RecordNotFound
    puts "No SubscriberList with id #{id}"
    true
  end

  def skip_govdelivery_id(id)
    puts "Skipping SubscriberList id #{id} due to gov_delivery_id mismatch"
    true
  end
end
