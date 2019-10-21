class QueueCourtesyEmailService
  def self.call(email_builder, content_change: nil, message: nil)
    raise ArgumentError.new("Filter must be either :for_content_change or :for_message") unless content_change || message

    subscriber = Subscriber.find_by(address: Email::COURTESY_EMAIL)
    return unless subscriber

    additional_parameter = content_change ? { content_change: content_change } : { message: message }
    email_id = email_builder.call([
                                      {
                                          address: subscriber.address,
                                          subscriptions: [],
                                          subscriber_id: subscriber.id,
                                      }.merge(additional_parameter),
                                  ]).ids.first

    DeliveryRequestWorker.perform_async_in_queue(
      email_id, queue: :delivery_immediate
    )
  end
end
