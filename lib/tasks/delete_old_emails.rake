desc "Deletes all emails older than 14 days old"
task delete_old_emails: :environment do
  count = 0
  two_weeks_ago = 2.weeks.ago
  Email.where("created_at < ?", two_weeks_ago).in_batches(of: 10_000) do |batch|
    count += batch.delete_all
    puts "#{count} emails deleted"
  end
end
