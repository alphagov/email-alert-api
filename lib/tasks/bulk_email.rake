namespace :bulk_email do
  desc "Send a bulk email to many subscriber lists. Any email addresses in config/bulk_email/email_addresses.txt will be skipped."
  task :for_lists, [] => :environment do |_t, args|
    puts "Enter email subject"
    subject = $stdin.gets.chomp
    puts "Enter email body"
    body = $stdin.gets.chomp

    subscriber_lists = SubscriberList.where(id: args.extras)
    email_ids = BulkSubscriberListEmailBuilder.call(
      subject: subject,
      body: body,
      subscriber_lists:,
    )
    email_ids.each do |id|
      SendEmailJob.perform_async_in_queue(id, queue: :send_email_immediate)
    end
    puts "Sending #{email_ids.count} emails to subscribers on the following lists: #{subscriber_lists.pluck(:slug).join(', ')}"
  end

  desc "Send a bulk email to many subscriber lists but only if the subscriber's email addresses are in config/bulk_email/email_addresses.txt."
  task :for_lists_and_explicitly_including_addresses, [] => :environment do |_t, args|
    puts "Enter email subject"
    subject = $stdin.gets.chomp
    puts "Enter email body"
    body = $stdin.gets.chomp

    subscriber_lists = SubscriberList.where(id: args.extras)
    email_ids = BulkSubscriberListEmailBuilderWithAccount.call(
      subject: subject,
      body: body,
      subscriber_lists:,
    )
    email_ids.each do |id|
      SendEmailJob.perform_async_in_queue(id, queue: :send_email_immediate)
    end
    puts "Sending #{email_ids.count} emails to subscribers on the following lists: #{subscriber_lists.pluck(:slug).join(', ')}"
  end

  desc "Send a bulk email to users that are subscribed to specific subscription lists"
  task for_subscriber_lists: :environment do
    subscriber_lists = %w[
      department-for-culture-media-and-sport-9a1e4ff9b9
      all-announcements-about-all-topics-by-department-for-culture-media-sport
      all-publications-about-all-topics-by-department-for-culture-media-sport
      consultations-about-all-topics-by-department-for-culture-media-sport
      policy-papers-and-consultations-with-organisation-of-department-for-culture-media-and-sport
      news-stories-related-to-department-for-culture-media-sport
      press-releases-about-all-topics-by-department-for-culture-media-sport
    ]

    subscriber_lists.each do |subscriber_list|
      SubscriberList.find_by(slug: subscriber_list)

      email_ids = BulkSubscriberListEmailBuilderSubscriptions.call(subscriber_list:)

      email_ids.each do |id|
        SendEmailJob.perform_async_in_queue(id, queue: :send_email_immediate)
      end

      puts "Sending #{email_ids.count} emails to subscribers on subscriber list: #{subscriber_list.title}"
    end
  end
end
