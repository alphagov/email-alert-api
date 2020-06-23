class ImmediateEmailGenerationService
  BATCH_SIZE = 5000

  def self.call(*args)
    new(*args).call
  end

  def initialize(content)
    @content = content
  end

  def call
    subscriber_batches.each do |batch|
      email_ids = batch.generate_emails
      email_ids.each do |id|
        DeliveryRequestWorker.perform_async_in_queue(
          id,
          worker_metrics,
          queue: content.queue,
        )
      end
    end
  end

  private_class_method :new

private

  attr_reader :content

  def subscriber_batches
    @subscriber_batches ||= begin
      scope = Subscription.for_content_change(content) if content.is_a?(ContentChange)
      scope = Subscription.for_message(content) if content.is_a?(Message)

      scope
        .active
        .immediately
        .subscription_ids_by_subscriber
        .each_slice(BATCH_SIZE)
        .map do |batch_of_subscribers|
          Batch.new(content, batch_of_subscribers.to_h)
        end
    end
  end

  def worker_metrics
    @worker_metrics ||= case content
                        when ContentChange
                          { "content_change_created_at" => content.created_at.iso8601 }
                        else
                          {}
                        end
  end
end
