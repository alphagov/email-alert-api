desc "Deletes all emails older than 14 days old"
task delete_old_emails: :environment do
  two_weeks_ago = 14.days.ago
  deleted_count = Email.where("created_at < ?", two_weeks_ago).delete_all

  "#{deleted_count} pending emails deleted older than #{two_weeks_ago}"
end
