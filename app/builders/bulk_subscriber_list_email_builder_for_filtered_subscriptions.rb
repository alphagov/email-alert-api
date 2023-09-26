class BulkSubscriberListEmailBuilderForFilteredSubscriptions
  def initialize(subscriber_list)
    @subscriber_list = subscriber_list
  end

  attr_reader :subscriber_list

  def call
    records_to_insert.empty? ? [] : Email.insert_all!(records_to_insert).pluck("id")
  end

  def target_subscriptions
    subscriber_list
      .subscriptions
      .where(ended_reason: "bulk_unsubscribed")
      .select { |sub| unsubscribed_on_target_date?(sub.ended_at) }
  end

  def unsubscribed_on_target_date?(date_str)
    (date_str.day == 22) && (date_str.month == 9) && (date_str.year == 2023)
  end

  def records_to_insert
    target_subscriptions.map do |subscription|
      subscriber = subscription.subscriber

      {
        address: subscriber.address,
        subject: email_subject,
        body: email_body,
        subscriber_id: subscriber.id,
        created_at: Time.zone.now,
        updated_at: Time.zone.now,
      }
    end
  end

  def email_body
    <<~BODY
      You asked GOV.UK to email you when we add or update a page about Trade marks.

      We emailed you earlier to say that the Trade marks page has been archived. The email included the wrong link for where you can find out more information about the topic.

      You can find out more information about intellectual property trade marks at https://www.gov.uk/government/collections/intellectual-property-trade-marks

      You can also sign up for email updates on that page if you would like to continue to get email updates from GOV.UK about trade marks.
    BODY
  end

  def email_subject
    "CORRECTION - Update from GOV.UK for: Trade marks"
  end
end
