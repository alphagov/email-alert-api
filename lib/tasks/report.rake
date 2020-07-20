namespace :report do
  desc "Query how many active subscribers there are to the given subscription slug"
  task :count_subscribers, %i[subscription_list_slug] => :environment do |_t, args|
    Reports::CountSubscribersReport.new.call(slug: args[:subscription_list_slug])
  end

  desc "Query how many active subscribers there are to the given subscription slug at the given point in time"
  task :count_subscribers_on, %i[date subscription_list_slug] => :environment do |_t, args|
    Reports::CountSubscribersOnReport.new.call(slug: args[:subscription_list_slug],
                                               date: args[:date])
  end

  desc "Export the number of subscriptions for the 'Living in' taxons for European countries as of a given date (format: 'yyyy-mm-dd')"
  task :csv_from_living_in_europe, [:date] => :environment do |_, args|
    Reports::LivingInEuropeReport.new.call(args.date)
  end
end
