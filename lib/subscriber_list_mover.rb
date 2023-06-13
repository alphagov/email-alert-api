class SubscriberListMover
  attr_reader :from_slug, :to_slug, :send_email

  def initialize(from_slug:, to_slug:, send_email: false)
    @send_email = send_email
    @from_slug = from_slug
    @to_slug = to_slug
  end

  def call
    source_subscriber_list = SubscriberList.find_by(slug: from_slug)
    raise "Source subscriber list #{from_slug} does not exist" if source_subscriber_list.nil?

    source_subscriptions = Subscription.active.find_by(subscriber_list_id: source_subscriber_list.id)
    raise "No active subscriptions to move from #{from_slug}" if source_subscriptions.nil?

    destination_subscriber_list = SubscriberList.find_by(slug: to_slug)
    raise "Destination subscriber list #{to_slug} does not exist" if destination_subscriber_list.nil?

    subscribers = source_subscriber_list.subscribers
    sub_count = source_subscriber_list.subscriptions.active.count
    puts "#{sub_count} active subscribers moving from #{from_slug} to #{to_slug}"

    if send_email
      emails_for_subscribed = build_emails(source_subscriber_list)
    end

    subscribers.each do |subscriber|
      Subscription.transaction do
        existing_subscription = Subscription.active.find_by(
          subscriber:,
          subscriber_list: source_subscriber_list,
        )

        next unless existing_subscription

        existing_subscription.end(reason: :subscriber_list_changed)

        subscribed_to_destination_subscriber_list = Subscription.find_by(
          subscriber:,
          subscriber_list: destination_subscriber_list,
        )

        if subscribed_to_destination_subscriber_list.nil?
          Subscription.create!(
            subscriber:,
            subscriber_list: destination_subscriber_list,
            frequency: existing_subscription.frequency,
            source: :subscriber_list_changed,
          )
        end
      end
    end

    puts "#{sub_count} active subscribers moved from #{from_slug} to #{to_slug}."

    if send_email
      puts "Sending emails to subscribers about change"
      email_change_to_subscribers(emails_for_subscribed)
    end
  end

  def build_emails(source_subscriber_list)
    email_subject = "Changes to GOV.UK emails"
    list_title = source_subscriber_list.title

    email_redirect = PublicUrls.url_for(
      base_path: "/email/manage",
      utm_campaign: "govuk-subscription-ended",
      utm_source: from_slug,
    )

    bulk_move_template = <<~BODY.freeze
      Hello,

      You’ve subscribed to get emails about #{list_title}.

      GOV.UK is changing the way we send emails, so you may notice a difference in the number and type of updates you get.

      You can [manage your subscription](#{email_redirect}) to choose how often you want to receive emails.

      Thanks,
      GOV.UK
    BODY

    BulkSubscriberListEmailBuilder.call(
      subject: email_subject,
      body: bulk_move_template,
      subscriber_lists: source_subscriber_list,
    )
  end

  def email_change_to_subscribers(emails_for_subscribed)
    emails_for_subscribed.each do |id|
      SendEmailWorker.perform_async_in_queue(id, queue: :send_email_immediate)
    end
  end
end
