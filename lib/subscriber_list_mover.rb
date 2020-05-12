class SubscriberListMover
  attr_reader :from_slug, :to_slug, :send_email

  def initialize(from_slug:, to_slug:, send_email: false)
    @send_email = send_email
    @from_slug = from_slug
    @to_slug = to_slug
  end

  def call
    source_subscriber_list = SubscriberList.find_by(slug: from_slug)
    sub_count = source_subscriber_list.subscriptions.active.count
    raise "Source subscriber list #{from_slug} does not exist" if source_subscriber_list.nil?

    source_subscriptions = Subscription.active.find_by(subscriber_list_id: source_subscriber_list.id)
    raise "No active subscriptions to move from #{from_slug}" if source_subscriptions.nil?

    destination_subscriber_list = SubscriberList.find_by(slug: to_slug)
    raise "Destination subscriber list #{to_slug} does not exist" if destination_subscriber_list.nil?

    subscribers = source_subscriber_list.subscribers.activated
    puts "#{sub_count} active subscribers moving from #{from_slug} to #{to_slug}"

    if send_email
      email_change_to_subscribers(source_subscriber_list)
    end

    subscribers.each do |subscriber|
      Subscription.transaction do
        existing_subscription = Subscription.active.find_by(
          subscriber: subscriber,
          subscriber_list: source_subscriber_list,
        )

        next unless existing_subscription

        existing_subscription.end(reason: :subscriber_list_changed)

        subscribed_to_destination_subscriber_list = Subscription.find_by(
          subscriber: subscriber,
          subscriber_list: destination_subscriber_list,
        )

        if subscribed_to_destination_subscriber_list.nil?
          puts "Moving #{subscriber.address} with ID #{subscriber.id} to #{destination_subscriber_list.title} list"

          Subscription.create!(
            subscriber: subscriber,
            subscriber_list: destination_subscriber_list,
            frequency: existing_subscription.frequency,
            source: :subscriber_list_changed,
          )
        end
      end
    end

    puts "#{sub_count} active subscribers moved from #{from_slug} to #{to_slug}"
  end

  def email_change_to_subscribers(source_subscriber_list)
    email_subject = "Changes to GOV.UK email alerts"
    email_utm_parameters = {
      utm_source: from_slug,
      utm_medium: "email",
      utm_campaign: "govuk-subscription-ended",
    }
    email_redirect = EmailTemplateContext.new.add_utm("https://gov.uk/email/manage", email_utm_parameters)
    list_title = source_subscriber_list.title

    bulk_move_template = <<~BODY.freeze
      Hello,

      You've subscribed to get email alerts about #{list_title} information.

      GOV.UK is changing the type of email alerts you get to make sure you find out when any #{list_title} guidance is added or updated.
      You can [change how often you get updates or unsubscribe](#{email_redirect}) from GOV.UK email alerts.

      Thanks,
      GOV.UK
    BODY

    BulkEmailSenderService.call(
      subject: email_subject,
      body: bulk_move_template,
      subscriber_lists: source_subscriber_list,
    )
  end
end
