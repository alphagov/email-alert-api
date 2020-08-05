class EmailDeletionWorker
  include Sidekiq::Worker

  LOCK_NAME = "email_deletion_worker".freeze

  def perform
    Email.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
      start_time = Time.zone.now
      deleted_count = Email.deleteable.delete_all
      log_complete(deleted_count, start_time, Time.zone.now)
    end
  end

private

  def log_complete(deleted, start_time, end_time)
    seconds = (end_time - start_time).round(2)
    message = "Deleted #{deleted} emails in #{seconds} seconds"
    logger.info(message)
  end
end
