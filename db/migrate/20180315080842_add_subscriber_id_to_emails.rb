class AddSubscriberIdToEmails < ActiveRecord::Migration[5.1]
  def change
    add_reference :emails, :subscriber, index: false
  end
end
