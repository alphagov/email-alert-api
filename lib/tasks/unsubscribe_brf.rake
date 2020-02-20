namespace :brf do
  desc "Send an email to all users subscribed to the Business Readiness Finder and deactivate the subscriptions."
  task :unsubscribe, [] => :environment do
    UnsubscribeBRFService.call
  end
end
