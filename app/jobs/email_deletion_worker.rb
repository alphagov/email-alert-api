class EmailDeletionWorker < ApplicationWorker
  def perform
    run_with_advisory_lock(Email, "delete") do
      start_time = Time.zone.now
      deleted_count = Email.where("created_at < ?", 1.week.ago).delete_all
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
