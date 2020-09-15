class RecoverLostJobsWorker
  include Sidekiq::Worker

  def perform
    ContentChange.unprocessed.where("created_at <= ?", 1.hour.ago).pluck(:id).each do |content_change_id|
      ProcessContentChangeWorker.perform_async(content_change_id)
    end

    Message.unprocessed.where("created_at <= ?", 1.hour.ago).pluck(:id).each do |message_id|
      ProcessMessageWorker.perform_async(message_id)
    end

    DigestRunSubscriber.unprocessed.where("created_at <= ?", 1.hour.ago).pluck(:id).each do |digest_run_subscriber_id|
      DigestEmailGenerationWorker.perform_async(digest_run_subscriber_id)
    end

    DigestRun.daily.unprocessed.where("created_at <= ?", 1.hour.ago).pluck(:date).each do |date|
      DailyDigestInitiatorWorker.perform_async(date.to_s)
    end

    DigestRun.weekly.unprocessed.where("created_at <= ?", 1.hour.ago).pluck(:date).each do |date|
      WeeklyDigestInitiatorWorker.perform_async(date.to_s)
    end
  end
end
