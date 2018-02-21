namespace :deploy do
  desc "Truncate tables for live deploy. This will truncate emails, delivery_attempts, subscription_contents, subscribers, subscriptions, digest_runs, digest_run_subscriptions, content_changes and matched_content_changes"
  task truncate_tables: :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE emails, subscribers, content_changes, digest_runs RESTART IDENTITY CASCADE;")

    puts "** Sanity check row counts ** "
    ActiveRecord::Base.connection.tables.each do |table|
      next if %w(ar_internal_metadata schema_migrations).include?(table)
      klass = table.classify.constantize
      puts "#{klass}: #{klass.count}"
    end
  end
end
