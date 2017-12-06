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

  def self.test_email_generation_workers(number)
    new.test_email_generation_workers(number)
  end

  def test_email_generation_workers(number)
    puts "Creating subscriber list and content change"

    subscriber_list = create_test_subscriber_list
    content_change = create_test_content_change

    puts "Creating #{number} subscribers"

    subscribers = create_test_subscribers(number)

    puts "Creating #{number} subscriptions"
    subscriptions = create_subscriptions(subscribers: subscribers, subscriber_list: subscriber_list)

    puts "Creating #{number} subscription contents"
    subscription_contents = create_subscription_contents(subscriptions: subscriptions, content_change: content_change)

    puts "Running workers"

    subscription_contents.each do |subscription_content|
      EmailGenerationWorker.perform_async(subscription_content_id: subscription_content.id, priority: :low)
    end
  end

private

  def create_test_email(to:)
    Email.create!(address: to, body: "body", subject: "subject")
  end

  def create_test_subscriber_list(document_type: nil)
    document_type = SecureRandom.uuid unless document_type

    SubscriberList.create!(
      title: "title",
      gov_delivery_id: SecureRandom.uuid,
      document_type: document_type,
    )
  end

  def create_test_subscriber_lists(number, document_type_prefix:)
    number.times.map do |i|
      create_test_subscriber_list(document_type: "#{document_type_prefix}-#{i}")
    end
  end

  def create_test_content_change(document_type: nil)
    document_type = SecureRandom.uuid unless document_type

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
      document_type: document_type,
      publishing_app: "publishing app",
    )
  end

  def create_test_content_changes(number, document_type_prefix:)
    number.times.map do |i|
      create_test_content_change(document_type: "#{document_type_prefix}-#{i}")
    end
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
