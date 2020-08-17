class ProcessContentChangeWorker
  include Sidekiq::Worker

  sidekiq_options queue: :process_and_generate_emails,
                  lock: :until_executed,
                  unique_args: :uniqueness_with, # in upcoming version 7 of sidekiq-unique-jobs, :unique_args is replaced with :lock_args
                  on_conflict: :log

  def self.uniqueness_with(args)
    [args.first]
  end

  def perform(content_change_id)
    content_change = ContentChange.find(content_change_id)
    return if content_change.processed_at

    MatchedContentChangeGenerationService.call(content_change)
    ImmediateEmailGenerationService.call(content_change)

    queue_courtesy_email(content_change)
    content_change.update!(processed_at: Time.zone.now)
  end

private

  def queue_courtesy_email(content_change)
    subscriber = Subscriber.find_by(address: Email::COURTESY_EMAIL)
    return unless subscriber

    id = ContentChangeEmailBuilder.call([
      {
        address: subscriber.address,
        subscriptions: [],
        content_change: content_change,
        subscriber_id: subscriber.id,
      },
    ]).first

    DeliveryRequestWorker.perform_async_in_queue(id, queue: content_change.queue)
  end
end
