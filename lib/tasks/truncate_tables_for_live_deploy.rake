namespace :deploy do
  desc "Truncate tables for live deploy. This will truncate emails, delivery_attempts, subscription_contents, subscribers, subscriptions, digest_runs, digest_run_subscriptions, content_changes and matched_content_changes"
  task truncate_tables: :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE emails, subscribers, content_changes, digest_runs RESTART IDENTITY CASCADE;")
  end
end
