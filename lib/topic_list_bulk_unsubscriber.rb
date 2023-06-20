class TopicListBulkUnsubscriber
  include Callable

  def initialize(opts = {})
    opts.each { |k, v| instance_variable_set("@#{k}", v) }
  end

  def call
    bulk_email
    bulk_unsubscribe
  end

private

  attr_reader :list_slug, :redirect_title, :redirect_url

  def bulk_email
    puts "#{subscriber_list.active_subscriptions_count} subscribers of #{subscriber_list.title} will be emailed"

    email_ids = BulkSubscriberListEmailBuilder.call(
      subject: email_subject,
      body: email_body,
      subscriber_lists: [subscriber_list],
    )

    puts "#{email_ids.count} emails queued for delivery"

    email_ids.each do |id|
      SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
    end
  end

  def email_subject
    "Update from GOV.UK for: #{subscriber_list.title}"
  end

  def subscriber_list
    @subscriber_list ||= SubscriberList.find_by_slug(list_slug)
  end

  def email_body
    <<~BODY
      Update from GOV.UK for:
      #{subscriber_list.title}
      _________________________________________________________________
      You asked GOV.UK to email you when we add or update a page about:
      #{subscriber_list.title}
      This topic has been archived. You will not get any more emails about it.
      You can find more information about this topic at [#{redirect_title}](#{redirect_url}).
    BODY
  end

  def bulk_unsubscribe
    subscriptions = subscriber_list.subscriptions.active
    subscriptions.each do |subscription|
      subscription.end(reason: 8)
    end

    puts "#{subscriber_list.active_subscriptions_count} subscribers left for #{subscriber_list.title}"
  end
end
