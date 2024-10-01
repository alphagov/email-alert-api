class SubscriberListMover
  attr_reader :from_slug, :to_slug, :send_email

  def initialize(from_slug:, to_slug:, send_email: false)
    @send_email = send_email
    @from_slug = from_slug
    @to_slug = to_slug
  end

  def call
    raise "Source subscriber list #{from_slug} does not exist" if source_subscriber_list.nil?
    raise "Destination subscriber list #{to_slug} does not exist" if destination_subscriber_list.nil?

    an_active_subscription = Subscription.active.find_by(subscriber_list_id: source_subscriber_list.id)
    raise "No active subscriptions to move from #{from_slug}" if an_active_subscription.blank?

    active_subscription_count = source_subscriber_list.subscriptions.active.count

    if send_email
      emails = BulkSubscriberListEmailBuilder.call(
        subject: email_subject,
        body: email_body,
        subscriber_lists: source_subscriber_list,
      )
    end

    BulkMigrateListJob.perform_async(
      source_subscriber_list.id,
      destination_subscriber_list.id,
    )

    puts "#{active_subscription_count} active subscribers moved from #{from_slug} to #{to_slug}."

    if send_email
      puts "Sending emails to subscribers about change"
      emails.each { |id| SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate) }
    end
  end

private

  def source_subscriber_list
    @source_subscriber_list ||= SubscriberList.find_by(slug: from_slug)
  end

  def destination_subscriber_list
    @destination_subscriber_list ||= SubscriberList.find_by(slug: to_slug)
  end

  def email_subject
    "Changes to GOV.UK emails"
  end

  def email_body
    email_redirect = PublicUrls.url_for(
      base_path: "/email/manage",
      utm_campaign: "govuk-subscription-ended",
      utm_source: from_slug,
    )

    <<~BODY.freeze
      Hello,

      You’ve subscribed to get emails about #{source_subscriber_list.title}.

      GOV.UK is changing the way we send emails, so you may notice a difference in the number and type of updates you get.

      You can [manage your subscription](#{email_redirect}) to choose how often you want to receive emails.

      Thanks,
      GOV.UK
    BODY
  end
end
