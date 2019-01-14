namespace :report do
  desc "Query the Notify API for email(s) by reference"
  task :get_notifications_from_notify, [:reference] => :environment do |_t, args|
    Reports::NotificationsFromNotify.call(args[:reference])
  end

  desc "Query the Notify API for email(s) by email ID"
  task :get_notifications_from_notify_by_email_id, [:id] => :environment do |_t, args|
    delivery_attempts = DeliveryAttempt.where(email_id: args[:id])

    if delivery_attempts.count.zero?
      puts "No results returned"
    else
      delivery_attempts.each do |delivery_attempt|
        Reports::NotificationsFromNotify.call(delivery_attempt.id)
      end
    end
  end
end
