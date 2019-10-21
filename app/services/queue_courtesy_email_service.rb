class QueueCourtesyEmailService
  def initialize(content_change_or_message)
    raise ArgumentError.new("Must be a Message or a Content Change") unless
        content_change_or_message.is_a?(Message) ||
          content_change_or_message.is_a?(ContentChange)

    @content_change_or_message = content_change_or_message
  end

  def self.call(*args)
    new(*args).call
  end

  def call
    return unless subscriber

    DeliveryRequestWorker.perform_async_in_queue(
      email_id, queue: :delivery_immediate
    )
  end

private

  attr_reader :content_change_or_message

  def subscriber
    @subscriber ||= Subscriber.find_by(address: Email::COURTESY_EMAIL)
  end

  def email_builder_parameter
    is_a_content_change? ? { content_change: content_change_or_message } : { message: content_change_or_message }
  end

  def email_builder
    is_a_content_change? ? ContentChangeEmailBuilder : MessageEmailBuilder
  end

  def email_id
    email_builder.call([
                          {
                            address: subscriber.address,
                            subscriptions: [],
                            subscriber_id: subscriber.id,
                          }.merge(email_builder_parameter),
                      ]).ids.first
  end

  def is_a_content_change?
    content_change_or_message.is_a?(ContentChange)
  end
end
