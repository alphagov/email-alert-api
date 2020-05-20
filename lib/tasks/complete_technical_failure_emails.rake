namespace :complete_technical_failure_emails do
  desc "Update emails marked as technical failure to have a completed_at time"
  task fill_completed_at_time: :environment do
    incomplete_technical_failure_emails = Email.where(failure_reason: :technical_failure, finished_sending_at: nil).includes(:delivery_attempt)
    incomplete_technical_failure_emails.find_each do |email|
      email.update(finished_sending_at: email.delivery_attempts.last.created_at)
    end
  end
end
