class AddSubscriberIdToEmails < ActiveRecord::Migration[5.1]
  def change
    add_reference :emails, :subscriber, index: true
    add_foreign_key :emails, :subscribers, on_delete: :restrict
  end
end
