class RecoverLostJobsWorker::OldPendingEmailsCheck
  def call
    old_pending_emails = Email.where(status: :pending)
                              .where("created_at <= ?", 3.hours.ago)

    recover(old_pending_emails)
  end

private

  def recover(old_pending_emails)
    old_pending_emails.in_batches do |relation|
      relation.pluck(:id).each do |id|
        SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
      end
    end
  end
end
