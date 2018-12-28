namespace :report do
  desc "Produce a report on the unpublishing activity between two dates/times. E.g [2018\06/17 12:20:20, 2018\06/18 13:20:20]"
  task :unpublishing, %i[start_date end_date] => :environment do |_t, args|
    Reports::UnpublishingReport.call(args[:start_date], args[:end_date])
  end
end
