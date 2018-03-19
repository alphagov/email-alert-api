class AddSubscriberIdToEmails < ActiveRecord::Migration[5.1]
  def up
    add_reference :emails, :subscriber

    execute %(
      ALTER TABLE "emails"
      ADD CONSTRAINT emails_subscriber_id_fk
      FOREIGN KEY ("subscriber_id") REFERENCES "subscribers" ("id")
      ON DELETE CASCADE NOT VALID
    )
  end

  def down
    remove_reference :emails, :subscriber
  end
end
