class RecoverLostJobsWorker
  include Sidekiq::Worker

  def perform
    old_unprocessed(ContentChange).pluck(:id).each do |content_change_id|
      ProcessContentChangeWorker.perform_async(content_change_id)
    end

    old_unprocessed(Message).pluck(:id).each do |message_id|
      ProcessMessageWorker.perform_async(message_id)
    end

    old_unprocessed(DigestRunSubscriber).pluck(:id).each do |digest_run_subscriber_id|
      DigestEmailGenerationWorker.perform_async(digest_run_subscriber_id)
    end

    old_unprocessed(DigestRun.daily).pluck(:date).each do |date|
      DailyDigestInitiatorWorker.perform_async(date.to_s)
    end

    old_unprocessed(DigestRun.weekly).pluck(:date).each do |date|
      WeeklyDigestInitiatorWorker.perform_async(date.to_s)
    end
  end

private

  def old_unprocessed(scope)
    scope.where(processed_at: nil).where("created_at <= ?", 1.hour.ago)
  end
end
