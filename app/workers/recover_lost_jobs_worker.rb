class RecoverLostJobsWorker
  include Sidekiq::Worker

  def perform
    ContentChange.unprocessed.where("created_at <= ?", 1.hour.ago).pluck(:id).each do |content_change_id|
      ProcessContentChangeWorker.perform_async(content_change_id)
    end

    Message.unprocessed.where("created_at <= ?", 1.hour.ago).pluck(:id).each do |message_id|
      ProcessMessageWorker.perform_async(message_id)
    end
  end
end
