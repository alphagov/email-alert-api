namespace :report do
  namespace :subscribers do
    desc "For a set of email addresses, produce a report of the Subscriptions in JSON format"
    task :subscriptions_for, [:emails] => :environment do |_t, args|
      raise ArgumentError.new("Missing email addresse(s)") unless args[:emails].present?

      Reports::SubscriberSubscriptions.call(email_addresses: args[:emails].split)
    end
  end
end
