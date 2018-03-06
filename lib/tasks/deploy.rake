namespace :deploy do
  def puts_table_counts
    ActiveRecord::Base.connection.tables.each do |table|
      next if %w(ar_internal_metadata schema_migrations).include?(table)
      klass = table.classify.constantize
      puts "#{klass}: #{klass.count}"
    end
  end

  desc "Truncate tables for live deploy. This will truncate emails, delivery_attempts, subscription_contents, subscribers, subscriptions, digest_runs, digest_run_subscriptions, content_changes, matched_content_changes and email_archives"
  task truncate_tables: :environment do
    ActiveRecord::Base.connection.execute("TRUNCATE emails, subscribers, content_changes, digest_runs, email_archives  RESTART IDENTITY CASCADE;")

    puts "** Sanity check row counts ** "
    puts_table_counts
  end

  desc "Output a table count"
  task count_tables: :environment do
    puts_table_counts
  end
end
