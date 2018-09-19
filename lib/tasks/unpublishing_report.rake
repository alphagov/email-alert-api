namespace :unpublishing do
  desc "Produce a report on the unpublishing activity between two dates.
        E.g [2018\06/17, 2018\06/18]"
  task :report, %i[start_date end_date] => :environment do |_t, args|
    UnpublishingReport.call(args[:start_date], args[:end_date])
  end
end
