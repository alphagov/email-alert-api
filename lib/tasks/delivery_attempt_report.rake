namespace :report do
  desc "Find successful delivery attempts between two dates/times and calculate average (seconds)"
  task :find_delivery_attempts, %i[start_date end_date] => :environment do |_t, args|
    raise ArgumentError.new("Missing start_date or end_date") unless args[:start_date].present? && args[:end_date].present?

    Reports::EmailDeliveryAttempts.new(args[:start_date], args[:end_date]).report
  end
end
