class LoadTester
  def self.test_delivery_request_workers(number)
    new.test_delivery_request_workers(number)
  end

  def test_delivery_request_workers(number)
    email = create_test_email(to: test_address(0))

    number.times do
      DeliveryRequestWorker.perform_async(email.id)
    end
  end

private

  def create_test_email(to:)
    Email.create!(address: to, body: "body", subject: "subject")
  end

  def create_test_subscriber_list
    SubscriberList.create!(
      title: "title",
      gov_delivery_id: SecureRandom.uuid,
    )
  end

  def create_test_content_change
    ContentChange.create!(
      content_id: SecureRandom.uuid,
      title: "title",
      base_path: "base path",
      change_note: "change note",
      description: "description",
      public_updated_at: DateTime.now,
      email_document_supertype: "email document supertype",
      government_document_supertype: "government document supertype",
      govuk_request_id: SecureRandom.uuid,
      document_type: "document type",
      publishing_app: "publishing app",
    )
  end

  def create_test_subscribers(n)
    n.times.map do |i|
      create_test_subscriber(number: i)
    end
  end

  def test_address(n)
    tag = n.to_s.rjust(8, "0")
    "success+#{tag}@simulator.amazonses.com"
  end

  def create_test_subscriber(number:)
    Subscriber.find_or_create_by!(address: test_address(number))
  end

  def create_subscriptions(subscribers:, subscriber_list:)
    records = subscribers.map do |subscriber|
      {subscriber_id: subscriber.id, subscriber_list_id: subscriber_list.id}
    end

    Subscription.create!(records)
  end

  def create_subscription_contents(subscriptions:, content_change:)
    records = subscriptions.map do |subscription|
      {content_change_id: content_change.id, subscription_id: subscription.id}
    end

    SubscriptionContent.create!(records)
  end
end
