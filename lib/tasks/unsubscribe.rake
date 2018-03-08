require 'csv'

namespace :unsubscribe do
  def unsubscribe(email_address)
    subscriber = Subscriber.find_by(address: email_address)
    if subscriber.nil?
      puts "Subscriber #{email_address} not found"
    else
      puts "Unsubscribing #{email_address}"
      UnsubscribeService.subscriber!(subscriber, :unsubscribed)
    end
  end

  desc "Unsubscribe a single subscriber"
  task :single, [:email_address] => :environment do |_t, args|
    unsubscribe(args[:email_address])
  end

  desc "Unsubscribe a list of subscribers from a CSV file"
  task :bulk_from_csv, [:csv_file_path] => :environment do |_t, args|
    email_addresses = CSV.read(args[:csv_file_path])
    email_addresses.each do |email_address|
      unsubscribe(email_address[0])
    end
  end
end
