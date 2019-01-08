namespace :report do
  desc "Query the Notify API for email(s) by reference"
  task :get_notifications_from_notify, [:reference] => :environment do |_t, args|
    Reports::NotificationsFromNotify.call(args[:reference])
  end
end
