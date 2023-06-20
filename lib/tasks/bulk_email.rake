namespace :bulk_email do
  desc "Send a bulk email to many subscriber lists. Any email addresses in config/bulk_email/email_addresses.txt will be skipped."
  task :for_lists, [] => :environment do |_t, args|
    subscriber_lists = SubscriberList.where(id: args.extras)
    email_ids = BulkSubscriberListEmailBuilder.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists:,
    )
    email_ids.each do |id|
      SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
    end
    puts "Sending #{email_ids.count} emails to subscribers on the following lists: #{subscriber_lists.pluck(:slug).join(', ')}"
  end

  desc "Send a bulk email to many subscriber lists but only if the subscriber's email addresses are in config/bulk_email/email_addresses.txt."
  task :for_lists_and_explicitly_including_addresses, [] => :environment do |_t, args|
    subscriber_lists = SubscriberList.where(id: args.extras)
    email_ids = BulkSubscriberListEmailBuilderWithAccount.call(
      subject: ENV.fetch("SUBJECT"),
      body: ENV.fetch("BODY"),
      subscriber_lists:,
    )
    email_ids.each do |id|
      SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
    end
    puts "Sending #{email_ids.count} emails to subscribers on the following lists: #{subscriber_lists.pluck(:slug).join(', ')}"
  end

  desc "Bulk unsubscribe archived specialist topic subscribers"
  task archived_specialist_topic_subscribers: :environment do
    data = [
      {
        "list_slug" => "immigration-rules-4f0e641750",
        "redirect_title" => "Visas and immigration operational guidance",
        "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
      },
      {
        "list_slug" => "asylum-policy",
        "redirect_title" => "Visas and immigration operational guidance",
        "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
      },
      {
        "list_slug" => "fees-and-forms",
        "redirect_title" => "Visas and immigration operational guidance",
        "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
      },
      {
        "list_slug" => "nationality-guidance",
        "redirect_title" => "Visas and immigration operational guidance",
        "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
      },
      {
        "list_slug" => "entry-clearance-guidance",
        "redirect_title" => "Visas and immigration operational guidance",
        "redirect_url" => "government/collections/visas-and-immigration-operational-guidance",
      },
      {
        "list_slug" => "immigration-staff-guidance",
        "redirect_title" => "Immigration staff guidance",
        "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
      },
      {
        "list_slug" => "business-auditing-accounting-and-reporting-38e0c4ed05",
        "redirect_title" => "Accounting for UK companies",
        "redirect_url" => "/guidance/accounting-for-uk-companies",
      },
      {
        "list_slug" => "enforcement",
        "redirect_title" => "Visas and immigration operational guidance",
        "redirect_url" => "government/collections/visas-and-immigration-operational-guidance",
      },
      {
        "list_slug" => "windrush-caseworker-guidance",
        "redirect_title" => "Visas and immigration operational guidance",
        "redirect_url" => "/government/collections/visas-and-immigration-operational-guidance",
      },
    ]

    data.each do |hash|
      TopicListBulkUnsubscriber.call(hash)
    end
  end
end
