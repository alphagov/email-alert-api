class UnsubscribeBRFService
  MESSAGE = <<~BODY.freeze
    goes here!
  BODY

  SUBJECT = "subject goes here".freeze

  def self.call
    UnsubscribeBRFService.new.call
  end

  def call
    subscriber_lists = SubscriberList.where("title like ?", "%Brexit guidance for your business%")
    puts "Unsubscribing #{subscriber_lists.count} subscriptions"
    subscriber_lists.inject(false) do |result, subscriber_list|
      puts "Unsubscribe #{subscriber_list.title}"
      result | process_subscriber_list(subscriber_list)
    end && send_courtesy_emails
  end

private

  def process_subscriber_list(subscriber_list)
    subscriptions = subscriber_list
                      .subscriptions
                      .includes(:subscriber)
                      .active

    return false if subscriptions.empty?

    email_parameters = subscriptions.map do |subscription|
      {
        address: subscription.subscriber.address,
        subject: SUBJECT,
        body: MESSAGE,
      }
    end

    email_ids = Email.import!(email_parameters).ids

    email_ids.zip(subscriptions) do |email_id, subscription|
      DeliveryRequestWorker.perform_async_in_queue(
        email_id,
        queue: :delivery_immediate,
      )

      subscription.update!(
        ended_reason: :unpublished,
        ended_at: Time.zone.now,
        ended_email_id: email_id,
      )
    end

    SubscriberDeactivationWorker.perform_async(
      subscriptions.map(&:subscriber_id),
    )
    true
  end

  def send_courtesy_emails
    subscribers = Subscriber.where(address: Email::COURTESY_EMAIL)
    email_parameters = subscribers.map do |subscriber|
      {
        address: subscriber.address,
        subject: SUBJECT,
        body: MESSAGE,
      }
    end

    email_ids = Email.import!(email_parameters).ids

    email_ids.each do |email_id|
      DeliveryRequestWorker.perform_async_in_queue(
        email_id,
        queue: :delivery_immediate,
      )
    end
  end
end
