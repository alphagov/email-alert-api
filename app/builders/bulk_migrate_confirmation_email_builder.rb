class BulkMigrateConfirmationEmailBuilder
  include Callable

  def initialize(source_id:, destination_id:, count:)
    @source_id = source_id
    @destination_id = destination_id
    @count = count
  end

  def call
    Email.create!(
      subject:,
      body:,
      address: ENV["BULK_MIGRATE_CONFIRMATION_EMAIL_ACCOUNT"],
    )
  end

private

  attr_reader :source_id, :destination_id, :count

  def subject
    "Bulk migration of #{source_subscriber_list_title} is complete"
  end

  def source_subscriber_list_title
    SubscriberList.find(source_id).title
  end

  def destination_subscriber_list_title
    SubscriberList.find(destination_id).title
  end

  def body
    <<~BODY
      #{count} subscriptions have been migrated:
      From "#{source_subscriber_list_title}"
      To "#{destination_subscriber_list_title}"

      No email notification has been sent to users.

      Thanks
      GOV.UK emails
    BODY
  end
end
