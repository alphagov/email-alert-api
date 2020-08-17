namespace :load_testing do
  desc "Generate a large number of content changes using the smallest number of lists"
  task :generate_emails_with_big_lists, %i[requested_volume] => :environment do |_t, args|
    requested_volume = args[:requested_volume].to_i
    raise("Specify a volume of emails to generate") unless requested_volume

    Overloader.new(requested_volume).with_big_lists
  end

  desc "Generate a large number of content changes using the biggest number of lists"
  task :generate_emails_with_small_lists, %i[requested_volume] => :environment do |_t, args|
    requested_volume = args[:requested_volume].to_i
    raise("Specify a volume of emails to generate") unless requested_volume

    Overloader.new(requested_volume).with_small_lists
  end

  desc "Clear any remaining load"
  task clear_emails: :environment do
    Sidekiq::Queue.all.each(&:clear)
  end
end
