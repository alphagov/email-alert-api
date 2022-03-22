namespace :archived_topics do
  desc "Send emails to subscribers of archived Specialist Topics and unsubscribe. Dry runs by default without `run` argument."
  task :email_and_unsubscribe, [:run] => :environment do |_t, args|
    args.with_defaults(run: "true")
    topic_urls.each do |topic|
      sub_list = SubscriberList.find_by(url: topic[:url])
      if !sub_list
        puts "No SubscriberList for #{topic[:url]}"
      else
        puts "Sending email for #{sub_list.url} (ID: #{sub_list.id})"
        puts "#{sub_list.subscribers.count} in this list"

        subject = "Update from GOV.UK for: #{sub_list.title}"

        body = <<~BODY
          Update from GOV.UK for:

          #{sub_list.title}

          _________________________________________________________________

          You asked GOV.UK to email you when we add or update a page about:


          #{sub_list.title}

          This topic has been archived. You will not get any more emails about it.

          You can find more information about this topic at [#{topic[:redirect_title]}](#{topic[:redirect]}).
        BODY

        puts "==============="
        puts "DRY RUN" unless args[:run] != "true"
        puts "CHECK OUTPUT"
        puts "First SubscriberList..."
        puts "The subscribers will see:"
        puts "subject: #{subject}"
        puts "body: #{body}"
        puts "First recipient #{sub_list.subscribers.first.address}" if sub_list.subscribers.count.positive?
        puts "==============="

        unless args[:run] == "true"
          email_ids = BulkSubscriberListEmailBuilder.call(
            subject: subject,
            body: body,
            subscriber_lists: [sub_list],
          )

          email_ids.each do |id|
            SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
          end

          puts "Destroying subscription list #{sub_list.url} (ID: #{sub_list.id})"
          sub_list.destroy!
        end
      end
    end
  end
end

def topic_urls
  [
    {
      "url": "/topic/business-tax/international-tax",
      "redirect": "/government/collections/double-taxation-relief-for-companies",
      "redirect_title": "Double Taxation Relief for companies",
    },
    {
      "url": "/topic/business-tax/life-insurance-policies",
      "redirect": "/guidance/reporting-of-chargeable-event-gains-life-insurance-policies",
      "redirect_title": "Report chargeable event gains for life insurance policies",
    },
  ]
end
