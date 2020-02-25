class UnsubscribeBRFService
  MESSAGE = <<~BODY.freeze
    You're getting this email because you subscribed to the "Find Brexit guidance for your business" finder. This tool has been removed from GOV.UK.

    Visit the [GOV.UK transition page](https://www.gov.uk/transition) instead to find out how to prepare your business for new rules in 2021.

    Regards,
    GOV.UK
  BODY

  SUBJECT = "\"Find Brexit guidance for your business\" finder on GOV.UK is discontinued".freeze

  def self.call
    UnsubscribeBRFService.new.call
  end

  def call
    subscriber_lists = SubscriberList.where("title like ?", "%Brexit guidance for your business%")
    all_subscriptions = subscriber_lists.flat_map { |list| list.subscriptions.active }
    return if all_subscriptions.empty?

    puts "Unsubscribing #{all_subscriptions.count} subscriptions"

    process_grouped_subscriptions all_subscriptions.group_by(&:subscriber)
    send_courtesy_emails
  end

private

  def process_grouped_subscriptions(grouped_subscriptions)
    grouped_subscriptions.each do |subscriber, subscriptions|
      email_id = send_email_to subscriber
      deactivate(subscriptions, email_id)
    end
  end

  def deactivate(subscriptions, email_id)
    subscriptions.each do |subscription|
      puts "deactivating #{subscription.subscriber_list.title}"
      subscription.update!(
        ended_reason: :unpublished,
        ended_at: Time.zone.now,
        ended_email_id: email_id,
        )
    end

    SubscriberDeactivationWorker.perform_async(
      subscriptions.pluck(:subscriber_id).uniq,
    )
  end

  def send_courtesy_emails
    subscribers = Subscriber.where(address: Email::COURTESY_EMAIL)
    subscribers.each { |subscriber| send_email_to subscriber }
  end

  def send_email_to(subscriber)
    email_parameters = {
      address: subscriber.address,
      subject: SUBJECT,
      body: MESSAGE,
    }

    email_id = Email.create!(email_parameters).id

    DeliveryRequestWorker.perform_async_in_queue(
      email_id,
      queue: :delivery_immediate,
    )

    email_id
  end
end
