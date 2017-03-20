desc "Some basic report from the logs"
task notification_log_reporting: :environment do
  start = ENV.fetch('REPORTING_PERIOD', 1).to_i.days.ago.beginning_of_day
  period = start..Time.zone.now

  reporting = NotificationLogReporting.new(period)

  reporting.duplicates.group_by(&:first).each do |app, duplicates|
    puts "#{duplicates.count} duplicates for #{app}"
    duplicates.each do |app, request_id, gov_delivery_ids_sets|
      puts "Duplicate for request id: #{request_id}"
      gov_delivery_ids_sets.uniq.each_with_index do |gov_delivery_ids, i|
        puts "Set #{i + 1}: #{gov_delivery_ids.join(', ')}"
      end
    end
  end

  if reporting.missing.count > 0
    puts "#{reporting.missing.count} missing from Email Alert API"
    reporting.missing.each do |gov_delivery_ids, count|
      puts "#{count} notifications"
      puts "GovUkDelivery: #{gov_delivery_ids}"
    end
  end

  if reporting.different.count > 0
    puts "#{reporting.different.count} with different gov delivery id sets"
    reporting.different.each do |(gov_uk_delivery_gov_delivery_ids, email_alert_api_gov_delivery_ids), count|
      puts "#{count} notifications"
      puts "GovUkDelivery: #{gov_uk_delivery_gov_delivery_ids}"
      puts "EmailAlertApi: #{email_alert_api_gov_delivery_ids}"
    end
  end
end
