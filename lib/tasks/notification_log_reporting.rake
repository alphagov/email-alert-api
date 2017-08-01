desc "Report for notification logs with optional `from` and `to` date params (e.g. `rake notification_log_reporting[2015-01-01,2016-02-02]`)"
task :notification_log_reporting, [:from, :to] => :environment do |_task, args|
  args.with_defaults(from: "2017-06-01", to: Time.now.to_s)

  from = Time.parse(args.from)
  to = Time.parse(args.to)

  puts "Reporting on Notifications from #{from.strftime("%d/%m/%Y")} to #{to.strftime("%d/%m/%Y")}\n"

  scope = NotificationLog.where(created_at: from..to)
  NotificationReport.new(scope).print
end
